const bigToUint8Array = (big) => {
  const big0 = BigInt(0)
  const big1 = BigInt(1)
  const big8 = BigInt(8)
  if (big < big0) {
    const bits = (BigInt(big.toString(2).length) / big8 + big1) * big8
    const prefix1 = big1 << bits
    big += prefix1
  }
  let hex = big.toString(16)
  if (hex.length % 2) {
    hex = '0' + hex
  }
  const len = hex.length / 2
  const u8 = new Uint8Array(len)
  let i = 0
  let j = 0
  while (i < len) {
    u8[i] = parseInt(hex.slice(j, j + 2), 16)
    i += 1
    j += 2
  }
  return u8
}

const u8ToNumber = (array) => {
  let number = 0;
  let pow = 0;
  for (let i = array.length - 1; i >= 0; i--) {
    number += array[i] * (256 ** pow);
    pow += 1;
  }
  return number;
}

const parseWebText = (webText) => {
  // webText is a struct. We get it in binary as a BigInt. However, since the system
  // is little endian, we cannot directly read and parse the BigInt as is. We need to
  // have a littleEndian aware converter. like the one above
  // webText struct -> { text: u32 (pointer), len: u32 }
  // after conversion -> { text: last 4 bytes, len: first 1-4 bytes }
  const bytes = bigToUint8Array(webText);
  // these are the reverse order of the struct because of the endianness.
  const start = bytes.length - 4;
  const len = bytes.slice(0, start);
  const text = bytes.slice(start, start+4);
  return {text: u8ToNumber(text), len: u8ToNumber(len)};
}

const getString = (webText) => {
  const str = parseWebText(webText);
  const bytes = new Uint8Array(memory.buffer, str.text, str.len);
  let s = ""
  for (let i = 0; i < str.len ; i++) {
    s += String.fromCharCode(bytes[i]);
  }
  return s;
}

const consoleLog = (value, len) => {
  const bytes = new Uint8Array(memory.buffer, value, len);
  let str = '';
  for (let i = 0; i < len; i++) {
    str += String.fromCharCode(bytes[i]);
  }
  console.log('zig1:', str);
  // console.log('zig2:', getString(value));
};

const milliTimestamp = () => {
  return BigInt(Date.now());
}

// we choose to always init the webgl context.
var canvas = document.getElementById("webgl_canvas");
var gl = canvas.getContext("webgl2");

// webgl does not store the state like opengl. So we have to do some of that work.
const glShaders = [];
const glPrograms = [];
const glVertexArrays = [];
const glBuffers = [];
const glTextures = [];
const glUniformLocations = [];

const glClearColor = (r,g,b,a) => {
  gl.clearColor(r, g, b, a);
}

const glClear = (mask) => {
  gl.clear(mask);
} 

const glBindFramebuffer = (target, framebuffer) => {
  let fb = null;
  if (framebuffer != 0) fb = framebuffer;
  gl.bindFramebuffer(target, fb)
}

const glUseProgram = (program) => {
  gl.useProgram(glPrograms[program]);
}

const glViewport = (x, y, width, height) => {
  gl.viewport(x, y, width, height)
}

const glEnable = (cap) => {
  gl.enable(cap);
}

const glBlendFunc = (sfactor, dfactor) => {
  gl.blendFunc(sfactor, dfactor);
}

// might need fix
const glGetUniformLocation = (programId, webText) => {
  glUniformLocations.push(gl.getUniformLocation(glPrograms[programId], getString(webText)));
  return glUniformLocations.length - 1;
};

const glUniform1i = (uniform, v0) => {
  gl.uniform1i(glUniformLocations[uniform], glUniformLocations[v0]);
}

const glCreateVertexArray = () => {
  glVertexArrays.push(gl.createVertexArray());
  return glVertexArrays.length - 1;
};

const glGenVertexArrays = (num, dataPtr) => {
  const vaos = new Uint32Array(memory.buffer, dataPtr, num);
  for (let n = 0; n < num; n++) {
    const b = glCreateVertexArray();
    vaos[n] = b;
  }
}

const glActiveTexture = (texture) => {
  gl.activeTexture(texture);
}

const glBindVertexArray = (va) => {
  gl.bindVertexArray(glVertexArrays[va]);
}

const glBindBuffer = (target, buffer) => {
  gl.bindBuffer(target, glBuffers[buffer]);
}

const glBufferData = (target, size, data, usage) => {
  if (target == 34962) { // GL_ARRAY_BUFFER
    size = Number(size);
    const buffer = new Float32Array(memory.buffer, data, size);
    gl.bufferData(target, buffer, usage);
  }
  if (target ==0x8893 ) { // GL_ELEMENT_ARRAY_BUFFER
    size = Number(size);
    const buffer = new Uint32Array(memory.buffer, data, size);
    gl.bufferData(target, buffer, usage);
  }

}

const glDrawElements = (mode, count, type, offset) => {
  gl.drawElements(mode, count, type, offset);
}

const glGenBuffers = (num, dataPtr) => {
  const buffers = new Uint32Array(memory.buffer, dataPtr, num);
  for (let n = 0; n < num; n++) {
    const b = glCreateBuffer();
    buffers[n] = b;
  }
}

const glVertexAttribPointer = (attribLocation, size, type, normalize, stride, offset) => {
  gl.vertexAttribPointer(attribLocation, size, type, normalize, stride, offset);
}

const glEnableVertexAttribArray = (x) => {
  gl.enableVertexAttribArray(x);
}

const glGenTextures = (num, dataPtr) => {
  const textures = new Uint32Array(memory.buffer, dataPtr, num);
  for (let n = 0; n < num; n++) {
    const b = glCreateTexture();
    textures[n] = b;
  }
}

const glTexImage2D = (target, level, internalFormat, width, height, border, format, type, dataPtr) => {
  const data = new Uint8Array(memory.buffer, dataPtr, width*height);
  console.log(data);
  gl.texImage2D(target, level, internalFormat, width, height, border, format, type, data);
};

const glTexParameteri = (target, pname, param) => {
  gl.texParameteri(target, pname, param);
}

const glCreateShader = (type) => {
  let shader = gl.createShader(type);
  glShaders.push(shader);
  return glShaders.length - 1;
}

const glShaderSource = (shader, count, data, len) => {
  if (count != 1) console.log("we only support count = 1 for glShaderSource");
  const source = new Uint8Array(memory.buffer, data, len);
  let str = '';
  for (let i = 0; i < len; i++) {
    str += String.fromCharCode(source[i]);
  }
  console.log('shader source = ', str);
  gl.shaderSource(glShaders[shader], str);
}

const glCompileShader = (shader) => {
  gl.compileShader(glShaders[shader]);
}

const glCreateProgram = () => {
  let program = gl.createProgram();
  glPrograms.push(program);
  return glPrograms.length - 1;
}

const glAttachShader = (program, shader) => {
  gl.attachShader(glPrograms[program], glShaders[shader]);
}

const glLinkProgram = (program) => {
  gl.linkProgram(glPrograms[program]);
}

const glDeleteShader = (shader) => {
  // eh who will delete and all
}

const glCreateBuffer = () => {
  glBuffers.push(gl.createBuffer());
  return glBuffers.length - 1;
}

const glCreateTexture = () => {
  glTextures.push(gl.createTexture());
  return glTextures.length - 1;
};

const glBindTexture = (target, textureId) => {
  gl.bindTexture(target, glTextures[textureId]);
}

var api = {
  consoleLogS: consoleLog,
  milliTimestamp,
  glClearColor,
  glClear,
  glBindFramebuffer,
  glUseProgram,
  glViewport,
  glEnable,
  glBlendFunc,
  glGetUniformLocation,
  glUniform1i,
  glActiveTexture,
  glBindTexture,
  glBindVertexArray,
  glBindBuffer,
  glBufferData,
  glDrawElements,
  glGenBuffers,
  glGenVertexArrays,
  glVertexAttribPointer,
  glEnableVertexAttribArray,
  glGenTextures,
  glTexImage2D,
  glTexParameteri,
  glCreateShader,
  glShaderSource,
  glCompileShader,
  glCreateProgram,
  glAttachShader,
  glLinkProgram,
  glDeleteShader,
  glCreateVertexArray,
  glCreateBuffer,
  glCreateTexture,
}
