const path = require("path");
const CompressionPlugin = require("compression-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");

const wasmFiles = [
    "binaryen/binaryen-box.wasm",
    "cpython/python.wasm",
    "cpython/python3.14.zip",
    "llvm/llvm-box.wasm",
    "quicknode/quicknode.wasm",
    "wasm-package/wasm-package.wasm",
];

const isProduction = process.env.NODE_ENV === "production";

module.exports = (env, argv) => {
    return {
        mode: argv.mode || "development",
        entry: path.resolve(__dirname, "index.js"),
        output: {
            filename: "[name].[contenthash].bundle.js",
            path: path.resolve(__dirname, "../build/demo"),
            clean: true,
            publicPath: "/",
        },
        resolve: {
            alias: {
                emception: path.resolve(__dirname, "../build/emception"),
            },
            fallback: {
                "path": false,
                "module": false,
                "node-fetch": false,
                "vm": false,
            },
        },
        plugins: [
            new HtmlWebpackPlugin({
                title: "Emception",
            }),
            new MonacoWebpackPlugin({
                languages: ["cpp"],

            }),
            new CopyWebpackPlugin({
                patterns: wasmFiles.map(file => ({
                    from: path.resolve(__dirname, `../build/emception/${file}`),
                    to: file,
                })),
            }),
            isProduction && new CompressionPlugin({
                filename: "[path][base].br",
                algorithm: "brotliCompress",
                test: /\.(js|wasm|css|html|svg|pack)$/,
            }),
        ],
        module: {
            rules: [
                {
                    test: /\.css$/i,
                    use: ["style-loader", "css-loader"],
                },
                {
                    test: /\.wasm$/i,
                    type: "asset/inline",
                },
                {
                    test: /\.(pack|br|a)$/i,
                    type: "asset/resource",
                },
                {
                    test: /\.worker\.m?js$/i,
                    exclude: /monaco-editor/,
                    use: {
                        loader: "worker-loader",
                        options: {
                            inline: "no-fallback",
                        },
                    },
                },
            ],
        },
        devServer: {
            allowedHosts: "auto",
            port: "auto",
            server: {
                type: "http",
            },
            headers: {
                "Cross-Origin-Embedder-Policy": "require-corp",
                "Cross-Origin-Opener-Policy": "same-origin",
            },
            hot: true,
        },
        optimization: {
            splitChunks: {
                chunks: "all",
            },
            runtimeChunk: "single",
        },
    };
};
