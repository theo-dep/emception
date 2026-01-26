import EmProcess from "./EmProcess.mjs";
import QuickNodeModule from "./quicknode/quicknode.mjs";

export default class QuickNodeProcess extends EmProcess {
    constructor(opts) {
        super(QuickNodeModule, { ...opts });
    }
};
