// ============================================================
// EDGE FUNCTION: send-push-notification
// بيتشغّل تلقائيًا كل ما يتضاف صف جديد في جدول announcements،
// وبيبعت إشعار Push حقيقي لكل الأجهزة المسجّلة (user_fcm_tokens)
// عن طريق Firebase Cloud Messaging.
// ============================================================
import { GoogleAuth } from "npm:google-auth-library@9";
import { createClient } from "npm:@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "autoonesa-df446";
const SITE_URL = "https://ysalama769-boop.github.io/auto_one_pro/";

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record) {
      return new Response(
        JSON.stringify({ error: "No record in payload" }),
        { status: 400 },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: tokens, error } = await supabase
      .from("user_fcm_tokens")
      .select("token");

    if (error) throw error;

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "No registered devices yet" }),
        { status: 200 },
      );
    }

    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;
    const auth = new GoogleAuth({
      credentials: JSON.parse(serviceAccountJson),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const client = await auth.getClient();
    const accessToken = (await client.getAccessToken()).token;

    const title = record.title ?? "AUTO ONE";
    const body = record.body ?? "";

    const sendResults = await Promise.allSettled(
      (tokens as { token: string }[]).map((row) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: row.token,
                notification: { title, body },
                webpush: {
                  fcm_options: { link: SITE_URL },
                },
              },
            }),
          },
        )
      ),
    );

    const successCount = sendResults.filter(
      (r) => r.status === "fulfilled",
    ).length;

    return new Response(
      JSON.stringify({
        totalDevices: tokens.length,
        sent: successCount,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
