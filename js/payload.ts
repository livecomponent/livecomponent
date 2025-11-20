import { RenderRequest } from "./live-component";

export const encode_request = async (request: RenderRequest): Promise<string> => {
  const payload = JSON.stringify(request);
  return encode(payload);
}

export const encode = async (data: string): Promise<string> => {
  const stream = new Blob([data], {type: "text/plain"}).stream();
  const compressed_stream = stream.pipeThrough(new CompressionStream("gzip"));
  const compressed_response = await new Response(compressed_stream);
  const compressed_blob = await compressed_response.blob()
  const buffer = await compressed_blob.arrayBuffer();
  return btoa(
    String.fromCharCode(
      ...new Uint8Array(buffer)
    )
  );
}

export const decode = async (data: string): Promise<string> => {
  // Decode base64 to binary data
  const arr = Uint8Array.from(atob(data), c => c.charCodeAt(0));

  if (is_gzipped(arr)) {
    // Decompress the gzipped data
    const stream = new Blob([arr]).stream();
    const decompressed_stream = stream.pipeThrough(new DecompressionStream("gzip"));
    const decompressed_response = await new Response(decompressed_stream);
    return decompressed_response.text();
  } else {
    // If not gzipped, convert the binary data to string
    return new TextDecoder().decode(arr);
  }
}

const is_gzipped = (data: Uint8Array): boolean => {
  // Check for gzip magic number (0x1F 0x8B)
  return data.length >= 2 && data[0] === 0x1F && data[1] === 0x8B;
}
