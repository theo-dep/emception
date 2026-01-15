const path = require("path");
const CompressionPlugin = require("compression-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");

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
                "llvm-box.wasm": false,
                "binaryen-box.wasm": false,
                "python.wasm": false,
                "quicknode.wasm": false,
                "path": false,
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
                patterns: [
                    {
                        from: path.resolve(__dirname, "../build/emception/brotli/brotli.wasm"),
                        to: "brotli/brotli.wasm",
                    },
                    {
                        from: path.resolve(__dirname, "../build/emception/wasm-package/wasm-package.wasm"),
                        to: "wasm-package/wasm-package.wasm",
                    },
                ],
            }),
            new CompressionPlugin({
                exclude: /\.br$/,
                filename: "[path][base].br",
                algorithm: "brotliCompress",
                test: /\.(js|css|html|svg)$/,
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
