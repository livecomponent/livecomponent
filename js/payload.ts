import { RenderRequest } from "./live-component";

export const encode_request = async (request: RenderRequest): Promise<string> => {
  const payload = JSON.stringify(request);
  const stream = new Blob([payload], {type: "text/plain"}).stream();
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
