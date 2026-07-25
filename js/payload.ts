import { RenderRequest } from "./live-component";

// Payload wire formats are NOT symmetric between request and response:
//
//   request:  base64(gzip?(JSON))       -- produced by encode_request
//   response: base64(gzip?(raw HTML))   -- consumed by decode_response
//
// Do not wrap response HTML in JSON "for symmetry" with the request side --
// decode_response() never JSON-parses, so it would render the escaped JSON
// string instead of markup.
//
// Only the client's own two directions get direction-pinned names. The
// base64/gzip primitive underneath them is used both ways -- by
// encode_request here, and by the tests that fabricate server responses --
// so it stays neutral as encode_payload.

// REQUEST side only. Serializes `request` to JSON, then base64/gzip-encodes
// it (matching ruby/lib/live_component/payload.rb#decode_request on the
// server).
export const encode_request = async (request: RenderRequest): Promise<string> => {
  const payload = JSON.stringify(request);
  return encode_payload(payload);
}

// Direction-neutral base64(gzip?) primitive.
export const encode_payload = async (data: string): Promise<string> => {
  if ("CompressionStream" in window && typeof window.CompressionStream === "function") {
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

  return btoa(data);
}

// RESPONSE side only. Expects base64(gzip?(raw HTML)) and returns the HTML
// string as-is -- this never JSON-parses (matching
// ruby/lib/live_component/payload.rb#encode_response on the server).
export const decode_response = async (data: string): Promise<string> => {
  // decode base64
  const arr = Uint8Array.from(atob(data), c => c.charCodeAt(0));

  if (is_gzipped(arr)) {
    const stream = new Blob([arr]).stream();
    const decompressed_stream = stream.pipeThrough(new DecompressionStream("gzip"));
    const decompressed_response = await new Response(decompressed_stream);
    return decompressed_response.text();
  } else {
    // not gzipped, convert binary data to string
    return new TextDecoder().decode(arr);
  }
}

const is_gzipped = (data: Uint8Array): boolean => {
  // check for gzip magic number (0x1F, 0x8B)
  return data.length >= 2 && data[0] === 0x1F && data[1] === 0x8B;
}
