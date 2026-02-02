import EmProcess from "./EmProcess.mjs";
import createEmscriptenModule from "./cpython/python.mjs";

export default class Python3Process extends EmProcess {
    constructor(opts) {
        const emscriptenSettings = {
            ...opts,
            async preRun(Module) {
                const versionInt = Module.HEAPU32[Module._Py_Version >>> 2];
                const major = (versionInt >>> 24) & 0xff;
                const minor = (versionInt >>> 16) & 0xff;
                // Prevent complaints about not finding exec-prefix by making a lib-dynload directory
                Module.FS.mkdirTree(`/lib/python${major}.${minor}/lib-dynload/`);
                Module.addRunDependency("install-stdlib");
                const resp = await fetch(`/cpython/python${major}.${minor}.zip`);
                const stdlibBuffer = await resp.arrayBuffer();
                Module.FS.writeFile(
                  `/lib/python${major}${minor}.zip`,
                  new Uint8Array(stdlibBuffer),
                  { canOwn: true },
                );
                Module.removeRunDependency("install-stdlib");
            },
        };

        super(createEmscriptenModule, emscriptenSettings);
    }
};
