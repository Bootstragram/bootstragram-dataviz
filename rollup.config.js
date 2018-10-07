import ascii from "rollup-plugin-ascii";
import node from "rollup-plugin-node-resolve";
import json from "rollup-plugin-json";
import {terser} from "rollup-plugin-terser";

import * as meta from "./package.json";

const copyright = `// ${meta.homepage} v${meta.version} Copyright ${(new Date).getFullYear()} ${meta.author.name}`;

export default [
  {
    input: "index",
    plugins: [
      node(),
      ascii(),
      json()
    ],
    output: {
      extend: true,
      banner: copyright,
      file: "dist/bootstragram-dataviz.js",
      format: "esm",
      indent: false,
      name: "d3"
    }
  },
  {
    input: "index",
    plugins: [
      node(),
      ascii(),
      terser({output: {preamble: copyright}}),
      json()
    ],
    output: {
      extend: true,
      file: "dist/bootstragram-dataviz.min.js",
      format: "esm",
      indent: false,
      name: "d3"
    }
  }
];
