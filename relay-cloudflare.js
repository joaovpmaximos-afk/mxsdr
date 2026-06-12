// ============================================================
// MxSDR — RELAY (Cloudflare Worker)
// Guarda a chave do Gemini EM SEGREDO. A equipe nunca vê a chave.
// Passo a passo: veja o arquivo COMO-LIGAR-A-IA.txt
// ------------------------------------------------------------
// 1) Cole sua chave do Gemini entre as aspas de GEMINI_KEY abaixo.
// 2) Deploy. Copie o endereço do worker e cole no MxSDR (Ajustes > Link do relay).
// ============================================================

const GEMINI_KEY = "COLE_AQUI_SUA_CHAVE_DO_GEMINI";
const MODELO = "gemini-2.0-flash";
// Domínios autorizados a usar o relay (o site do MxSDR):
const ORIGENS_PERMITIDAS = ["https://joaovpmaximos-afk.github.io"];

export default {
  async fetch(request) {
    const origin = request.headers.get("Origin") || "";
    const permitido = !origin || ORIGENS_PERMITIDAS.includes(origin);
    const acao = permitido ? (origin || "*") : ORIGENS_PERMITIDAS[0];
    const cors = {
      "Access-Control-Allow-Origin": acao,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "content-type",
      "Vary": "Origin",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    if (request.method !== "POST") return new Response("MxSDR relay no ar :)", { headers: cors });
    if (!permitido) return resp({ error: "origem nao autorizada" }, 403, cors);

    let body;
    try { body = await request.json(); } catch (e) { return resp({ error: "json invalido" }, 400, cors); }
    const prompt = body && body.prompt;
    if (!prompt) return resp({ error: "faltou o prompt" }, 400, cors);

    const url = "https://generativelanguage.googleapis.com/v1beta/models/" + MODELO + ":generateContent?key=" + GEMINI_KEY;
    let r, d;
    try {
      r = await fetch(url, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.6, maxOutputTokens: 8192 },
        }),
      });
      d = await r.json();
    } catch (e) { return resp({ error: "falha ao falar com o Gemini" }, 502, cors); }

    if (!r.ok) return resp({ error: (d.error && d.error.message) || ("HTTP " + r.status) }, 502, cors);
    if (d.promptFeedback && d.promptFeedback.blockReason) return resp({ error: "conteudo bloqueado: " + d.promptFeedback.blockReason }, 502, cors);
    const cand = (d.candidates || [])[0];
    const text = cand && cand.content ? (cand.content.parts || []).map(function (p) { return p.text || ""; }).join("") : "";
    return resp({ text: text }, 200, cors);
  },
};

function resp(obj, status, cors) {
  return new Response(JSON.stringify(obj), { status: status, headers: Object.assign({}, cors, { "content-type": "application/json" }) });
}
