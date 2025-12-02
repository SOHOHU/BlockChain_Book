import express from "express";
import cors from "cors";
import { handleGet, handlePost } from "./actions";

const app = express();
app.use(cors({ origin: "*" }));
app.use(express.json());

app.get("/api/vote", async (_req, res) => {
  try {
    const resp = await handleGet();
    res.json(resp);
  } catch (e: any) {
    res.status(500).json({ error: e?.message ?? String(e) });
  }
});

app.post("/api/vote", async (req, res) => {
  try {
    const resp = await handlePost(req.body);
    res.json(resp);
  } catch (e: any) {
    res.status(500).json({ error: e?.message ?? String(e) });
  }
});

// 预检支持
app.options("/api/vote", (_req, res) => {
  res.set({
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });
  res.sendStatus(200);
});

const port = 3000;
app.listen(port, () => {
  console.log(`Actions server running on http://localhost:${port}`);
});
