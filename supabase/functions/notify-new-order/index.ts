import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...cors,
      "Content-Type": "application/json",
    },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
  const CHAT_ID = Deno.env.get("TELEGRAM_CHAT_ID");
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!BOT_TOKEN || !CHAT_ID || !SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return json(
      { error: "Notification service is not configured" },
      500
    );
  }

  let payload: any;

  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  // Supabase Database Webhook sends the new row inside payload.record.
  const orderId = String(
    payload?.record?.order_id ||
    payload?.order_id ||
    ""
  ).trim();

  if (!/^SCM-\d{8}-\d{4}$/.test(orderId)) {
    return json({ error: "Invalid order id" }, 400);
  }

  const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: order, error } = await sb
    .from("orders")
    .select(
      "order_id,customer_name,customer_phone,customer_email,full_address,division,district,upazila,union_or_area,payment_method,total_amount,created_at,order_items"
    )
    .eq("order_id", orderId)
    .maybeSingle();

  if (error || !order) {
    console.error("Order lookup failed:", error);
    return json({ error: "Order not found" }, 404);
  }

  // Prevent duplicate Telegram notifications.
  const { data: claimed, error: claimError } = await sb
    .from("order_notification_log")
    .insert({ order_id: orderId })
    .select("order_id")
    .maybeSingle();

  if (claimError || !claimed) {
    return json({
      ok: true,
      already_notified: true,
    });
  }

  const items = Array.isArray(order.order_items)
    ? order.order_items
    : [];

  const productText = items.length
    ? items
        .map(
          (item: any) =>
            `• ${String(item.name || "Product")} × ${Number(
              item.quantity || 0
            )}`
        )
        .join("\n")
    : "• Order items unavailable";

  const address = [
    order.division,
    order.district,
    order.upazila,
    order.union_or_area,
    order.full_address,
  ]
    .filter(Boolean)
    .join(", ");

  const text = [
    "🚨 NEW ORDER — SparkCart Mall",
    "",
    `🆔 Order ID: ${order.order_id}`,
    `👤 Customer: ${order.customer_name || "-"}`,
    `📞 Phone: ${order.customer_phone || "-"}`,
    "",
    `📦 Products:`,
    productText,
    "",
    `💰 Total: ৳${Number(
      order.total_amount || 0
    ).toLocaleString("en-BD")}`,
    `💳 Payment: ${order.payment_method || "-"}`,
    "",
    `📍 Address: ${address || "-"}`,
    `⏰ Order Time: ${new Date(
      order.created_at
    ).toLocaleString("en-BD")}`,
  ].join("\n");

  const telegramResponse = await fetch(
    `https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chat_id: CHAT_ID,
        text,
        disable_web_page_preview: true,
      }),
    }
  );

  if (!telegramResponse.ok) {
    const errorText = await telegramResponse.text();
    console.error("Telegram error:", errorText);

    // Allow retry if Telegram failed.
    await sb
      .from("order_notification_log")
      .delete()
      .eq("order_id", orderId);

    return json(
      { error: "Telegram notification failed" },
      502
    );
  }

  return json({
    ok: true,
    order_id: orderId,
    notified: true,
  });
});
