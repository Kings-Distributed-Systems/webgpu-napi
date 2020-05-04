import WebGPU from "../index.js";

Object.assign(global, WebGPU);

const vsSrc = `
  #version 450
  #pragma shader_stage(vertex)
  const vec2 pos[3] = vec2[3](
    vec2(0.0f, 0.5f),
    vec2(-0.5f, -0.5f),
    vec2(0.5f, -0.5f)
  );
  void main() {
    gl_Position = vec4(pos[gl_VertexIndex], 0.0, 1.0);
  }
`;

const fsSrc = `
  #version 450
  #pragma shader_stage(fragment)
  layout(location = 0) out vec4 outColor;
  void main() {
    outColor = vec4(1.0, 0.0, 0.0, 1.0);
  }
`;

(async function main() {

  const window = new WebGPUWindow({
    width: 640,
    height: 480,
    title: "WebGPU",
    resizable: false
  });

  const adapter = await GPU.requestAdapter({ window });

  const device = await adapter.requestDevice();

  const queue = device.getQueue();

  const context = window.getContext("webgpu");

  const swapChainFormat = await context.getSwapChainPreferredFormat(device);

  const swapChain = context.configureSwapChain({
    device: device,
    format: swapChainFormat
  });

  const layout = device.createPipelineLayout({
    bindGroupLayouts: []
  });

  const vertexShaderModule = device.createShaderModule({ code: vsSrc });
  const fragmentShaderModule = device.createShaderModule({ code: fsSrc });

  const pipeline = device.createRenderPipeline({
    layout,
    vertexStage: {
      module: vertexShaderModule,
      entryPoint: "main"
    },
    fragmentStage: {
      module: fragmentShaderModule,
      entryPoint: "main"
    },
    primitiveTopology: "triangle-list",
    vertexInput: {
      indexFormat: "uint32",
      buffers: []
    },
    rasterizationState: {
      frontFace: "CCW",
      cullMode: "none"
    },
    colorStates: [{
      format: swapChainFormat,
      alphaBlend: {},
      colorBlend: {}
    }],
    sampleCount: 4
  });

  const texture = device.createTexture({
    size: {
      width: 640,
      height: 480,
      depth: 1
    },
    sampleCount: 4,
    format: swapChainFormat,
    usage: GPUTextureUsage.OUTPUT_ATTACHMENT
  });

  const attachment = texture.createView({
    format: swapChainFormat
  });

  function onFrame() {
    if (!window.shouldClose()) setTimeout(onFrame, 1e3 / 60);

    const backBufferView = swapChain.getCurrentTextureView();

    const commandEncoder = device.createCommandEncoder({});
    const renderPass = commandEncoder.beginRenderPass({
      colorAttachments: [{
        clearColor: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
        loadOp: "clear",
        storeOp: "store",
        attachment,
        resolveTarget: backBufferView
      }]
    });
    renderPass.setPipeline(pipeline);
    renderPass.draw(3, 1, 0, 0);
    renderPass.endPass();

    const commandBuffer = commandEncoder.finish();
    queue.submit([ commandBuffer ]);
    swapChain.present();
    window.pollEvents();
  };
  setTimeout(onFrame, 1e3 / 60);

})();
