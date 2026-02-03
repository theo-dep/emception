class WorkerManager {
    constructor(
        workerURL,
        standardIO,
        readyCallBack,
        finishedCallback,
    ) {
        this.workerURL = workerURL;
        this.worker = null;
        this.standardIO = standardIO;
        this.readyCallBack = readyCallBack;
        this.finishedCallback = finishedCallback;

        this.initialiseWorker();
    }

    async initialiseWorker() {
        if (!this.worker) {
            this.worker = new Worker(this.workerURL, {
                type: "module",
            });
            this.worker.addEventListener(
                "message",
                this.handleMessageFromWorker,
            );
        }
    }

    async run(options) {
        this.worker.postMessage({
            type: "run",
            args: options.args || [],
            files: options.files || {},
        });
    }

    reset() {
        if (this.worker) {
            this.worker.terminate();
            this.worker = null;
        }
        this.initialiseWorker();
    }

    handleMessageFromWorker = (event) => {
        const type = event.data.type;
        if (type === "ready") {
            this.readyCallBack();
        } else if (type === "stdout") {
            this.standardIO.stdout(event.data.stdout);
        } else if (type === "stderr") {
            this.standardIO.stderr(event.data.stderr);
        } else if (type === "finished") {
            this.finishedCallback(event.data.returnCode);
        }
    }
}

export default class Python3Process extends WorkerManager {
    _stdout = [];
    _stderr = [];
    _returnCode = 0;

    constructor(baseURI, readyCallBack = () => {}, finishedCallback = () => {}) {
        const stdio = {
            stdout: (charCode) => {
                this._stdout.push(charCode);
            },
            stderr: (charCode) => {
                this._stderr.push(charCode);
            },
        };

        const absoluteUrl = new URL("/cpython/python.worker.mjs", baseURI);
        super(absoluteUrl, stdio, readyCallBack, (returnCode) => {
            this._returnCode = returnCode;
            this.reset();
            finishedCallback();
        });
    }

    exec(args, files = {}) {
        this._stdout = [];
        this._stderr = [];
        this._returnCode = 0;

        this.run({
            args: args,
            files: files,
        });
        return {
            returncode: this._returnCode,
            stdout: this._stdout.join("\n"),
            stderr: this._stderr.join("\n"),
        }
    }
};
