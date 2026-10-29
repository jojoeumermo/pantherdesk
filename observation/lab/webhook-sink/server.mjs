// Minimal webhook receiver for the observation lab.
// Appends one JSON object per request to SINK_LOG and answers according to the path:
//   /status/<code>   -> responds with that HTTP status (to observe retry behaviour)
//   /slow/<ms>       -> waits <ms> before answering 200 (to observe timeouts)
//   anything else    -> 200
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

const port = Number(process.env.SINK_PORT ?? 8090);
const logPath = process.env.SINK_LOG ?? "/data/requests.jsonl";
let seq = 0;

createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", async () => {
    const body = Buffer.concat(chunks);
    const entry = {
      seq: ++seq,
      received_at: new Date().toISOString(),
      method: req.method,
      url: req.url,
      headers: req.headers,
      body_utf8: body.toString("utf8"),
      body_bytes: body.length,
    };
    appendFileSync(logPath, JSON.stringify(entry) + "\n");

    const [, kind, arg] = (req.url ?? "/").split("/");
    if (kind === "slow") await new Promise((r) => setTimeout(r, Number(arg) || 0));
    const status = kind === "status" ? Number(arg) || 500 : 200;
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify({ seq: entry.seq, status }));
  });
}).listen(port, () => console.log(`webhook sink listening on ${port}, logging to ${logPath}`));
