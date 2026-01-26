import BoxProcess from "./BoxProcess.mjs";
import LlvmBoxModule from "./llvm/llvm-box.mjs";

const tool_mapping = {
    "clang++": "clang",
    "wasm-ld": "lld",
};

export default class LlvmBoxProcess extends BoxProcess {
    constructor(opts) {
        super(LlvmBoxModule, { ...opts, tool_mapping });
    }
};
