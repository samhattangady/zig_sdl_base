const getString = (ptr) => {
  // we must find the length of null terminated string
  const bytes = new Uint8Array(memory.buffer, ptr);
  let s = ""
  for (let i = 0; ; ++i) {
    const c = String.fromCharCode(bytes[i]);
    if (c == "") break;
    s += c;
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
const glGetUniformLocation = (programId, namePtr) => {
  glUniformLocations.push(gl.getUniformLocation(glPrograms[programId], namePtr));
  return glUniformLocations.length - 1;
};

const glUniform1i = (program, v0) => {
  gl.uniform1i(glPrograms[program], v0);
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
  const buffer = new Float32Array(memory.buffer, data, size);
  gl.bufferData(target, buffer, usage);
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

const glTexImage2D = (target, level, internalFormat, width, height, border, format, type, dataPtr, dataLen) => {
  const data = new Uint8Array(memory.buffer, dataPtr, dataLen);
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
  console.log('shader source = ', source);
  gl.shaderSource(glShaders[shader], source);
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
