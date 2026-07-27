import { readdir } from "node:fs/promises";

const declarations = await readdir(new URL("../dist", import.meta.url), {
  recursive: true,
});
const leakedSmokeDeclarations = declarations.filter((path) =>
  path.startsWith("smoke/")
);

if (leakedSmokeDeclarations.length > 0) {
  throw new Error(
    `Smoke declarations leaked into dist: ${leakedSmokeDeclarations.join(", ")}`
  );
}
