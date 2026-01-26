import BoxProcess from "./BoxProcess.mjs";
import BinaryenBoxModule from "./binaryen/binaryen-box.mjs";

export default class BinaryenBoxProcess extends BoxProcess {
    constructor(opts) {
        super(BinaryenBoxModule, { ...opts });
    }
};
