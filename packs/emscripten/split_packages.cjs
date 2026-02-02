const cp = require("child_process");
const fs = require("fs");
const path = require("path");

function hash_folder(root) {
    return "h" + cp.execSync(`cd "${root}" && find . -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum`, { shell: "bash" }).toString().trim().split(" ")[0];
}

function weight_folder(root) {
    return parseInt(cp.execSync(`cd "${root}" && find . -type f -print0 | sort -z | xargs -0 cat | wc -c`, { shell: "bash" }).toString().trim().split(" ")[0]);
}

function folder_tree(root, parent = null) {
    const node = {
        name: path.basename(root),
        original_path: root,
        path_override: parent ? null : root,
        hash: hash_folder(root),
        size: weight_folder(root),
        parent: parent,
        children: {},
        self_size_override: null,
    };
    Object.defineProperty(node, "path", {
        get: () => {
            return node.path_override || path.join(node.parent.path, node.name);
        },
        set: (val) => {
            throw new Error("Use path_override instead");
        },
    });
    Object.defineProperty(node, "self_size", {
        get: () => {
            if (node.self_size_override !== null) return node.self_size_override;
            let size = node.own_size;
            for (const child of Object.values(node.children)) {
                if (!child.path_override) {
                    size += child.self_size;
                }
            }
            return size;
        },
        set: (val) => {
            throw new Error("Use self_size_override instead");
        },
    });
    Object.defineProperty(node, "own_size", {
        get: () => {
            let size = node.size;
            for (const child of Object.values(node.children)) {
                size -= child.size
            }
            return size;
        },
        set: (val) => {
            throw new Error("Can't override own_size");
        },
    });
    node.child = (path) => {
        let res = node;
        for (const part of path.split("/")) {
            res = res.children[part];
        }
        return res;
    };
    node.path_from = (parent, path_sep = "/") => {
        let p = node;
        let parts = [];
        while (p && p !== parent) {
            parts.unshift(p.name);
            p = p.parent;
        }
        return parts.join(path_sep);
    };
    for (const child of fs.readdirSync(root)) {
        const child_root = path.join(root, child);
        if (fs.statSync(child_root).isDirectory()) {
            node.children[child] = folder_tree(child_root, node);
        }
    };
    return node;
}

function dfs(tree, callback) {
    for (const node of Object.values(tree.children)) {
        const res = dfs(node, callback);
        if (res) return res;
    }
    return callback(tree);
}

// Split emscripten/ in smaller packages
const packages = [];
function pack(root, nodes, min_size = 1e6) {
    nodes = nodes.filter((node) => !node.path_override && node.self_size === node.size);

    let package_size = 0;
    for (const node of nodes) {
        package_size += node.self_size;
    }
    if (package_size < min_size) return false;

    for (const node of nodes) {
        node.path_override = path.join(root, node.name);
    }
    packages.unshift([root, nodes]);

    return true;
}

const full_tree = folder_tree("./emscripten");
const cache_tree = full_tree.child("cache");
const system_tree = full_tree.child("system");

// Split emscripten/system and emscripten/cache in smaller packages
for (const to_split of [system_tree, cache_tree]) {
    dfs(to_split, (node) => {
        const root = path.normalize(path.join(full_tree.path, "..", "emscripten_" + node.path_from(full_tree, "_")));
        if (pack(root, [node])) return;
        if (pack(root, Object.values(node.children))) return;
    });
}

// Split emscripten/system/ in smaller packages
for (const folder of ["node_modules", "src", "tools", "third_party"]) {
    const node = full_tree.child(folder);
    const root = path.normalize(path.join(full_tree.path, "..", `emscripten_${folder}`));
    pack(root, [node], 0);
}

for (const [root, content] of packages) {
    let self_size = 0;
    for (const node of content) {
        self_size += node.self_size;
    }
    cp.execSync(`mkdir -p ${root}`);
    for (const node of content) {
        cp.execSync(`mv ${path.join(node.parent.path, node.name)} ${node.path}`);
        cp.execSync(`ln -s ${path.relative(node.parent.path, node.path)} ${path.join(node.parent.path, node.name)}`);
    }
}
