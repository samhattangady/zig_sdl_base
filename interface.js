const consoleLog = (value, len) => {
  const bytes = new Uint8Array(memory.buffer, value, len);
  let str = '';
  for (let i = 0; i < len; i++) {
    str += String.fromCharCode(bytes[i]);
  }
  console.log('zig:', str);
};

const milliTimestamp = () => {
  return BigInt(Date.now());
}

// we choose to always init the webgl context.
var canvas = document.getElementById("webgl_canvas");
var gl = canvas.getContext("webgl2");

const glClearColor = (r,g,b,a) => {
  gl.clearColor(r, g, b, a);
}

const glClear = (mask) => {
  gl.clear(mask);
} 

const glGenVertexArrays = (num, dataPtr) => {
  const vaos = new Uint32Array(memory.buffer, dataPtr, num);
  for (let n = 0; n < num; n++) {
    const b = glCreateVertexArray();
    vaos[n] = b;
  }
}

var api = {
  consoleLogS: consoleLog,
  milliTimestamp,
  glClearColor,
  glClear,
}
