import EmProcess from "./EmProcess.mjs";
import PythonModule from "./cpython/python.mjs";

export default class Python3Process extends EmProcess {
    constructor(opts) {
        super(PythonModule, { ...opts });
    }
};
