import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY") ?? "";
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY") ?? "";
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") ?? "mailto:admin@worshiplamal.app";

if (VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) {
  webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
}

serve(async (req: Request) => {
  try {
    const { setlistId, eventType, setlistTitle } = await req.json();
    if (!setlistId) {
      return new Response(JSON.stringify({ error: "Missing setlistId" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 1. Fetch setlist owner and title
    const { data: setlist } = await supabase
      .from("setlists")
      .select("user_id, title")
      .eq("id", setlistId)
      .maybeSingle();

    const ownerId = setlist?.user_id as string | undefined;
    const resolvedTitle = setlistTitle ?? setlist?.title ?? "Shared Setlist";

    // 2. Fetch followers from setlist_subscriptions, excluding the owner
    let followersQuery = supabase
      .from("setlist_subscriptions")
      .select("user_id")
      .eq("setlist_id", setlistId);

    if (ownerId) {
      followersQuery = followersQuery.neq("user_id", ownerId);
    }

    const { data: subs } = await followersQuery;
    if (!subs?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "no followers" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const followerIds = subs.map((s: { user_id: string }) => s.user_id);

    // 3. Fetch push subscriptions for followers
    const { data: pushSubs } = await supabase
      .from("push_subscriptions")
      .select("endpoint, p256dh, auth")
      .in("user_id", followerIds);

    if (!pushSubs?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "no push subs" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Send Web Push notifications
    const payload = JSON.stringify({
      title: "Worship Lamal",
      body: eventType === "created"
        ? `New setlist: "${resolvedTitle}"`
        : `Setlist updated: "${resolvedTitle}"`,
      icon: "/icons/Icon-192.png",
      badge: "/icons/Icon-192.png",
      data: { url: `/setlist/${setlistId}` },
    });

    const results = await Promise.allSettled(
      pushSubs.map((sub: { endpoint: string; p256dh: string; auth: string }) =>
        webpush.sendNotification(
          {
            endpoint: sub.endpoint,
            keys: { p256dh: sub.p256dh, auth: sub.auth },
          },
          payload,
        )
      ),
    );

    // 5. Clean up expired/unsubscribed endpoints (410 Gone)
    const expiredEndpoints: string[] = [];
    results.forEach((result, index) => {
      if (
        result.status === "rejected" &&
        result.reason?.statusCode === 410
      ) {
        expiredEndpoints.push(pushSubs[index].endpoint);
      }
    });

    if (expiredEndpoints.length > 0) {
      await supabase
        .from("push_subscriptions")
        .delete()
        .in("endpoint", expiredEndpoints);
    }

    const sentCount = results.filter((r) => r.status === "fulfilled").length;
    return new Response(
      JSON.stringify({ sent: sentCount, cleaned: expiredEndpoints.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
