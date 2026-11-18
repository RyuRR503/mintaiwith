import { createFileRoute } from "@tanstack/react-router";
import showreelAsset from "@/assets/mint-ai-showreel.mp4.asset.json";

export const Route = createFileRoute("/video")({
  head: () => ({
    meta: [
      { title: "MINT.AI — Video" },
      { name: "description", content: "MINT.AI video." },
      { name: "robots", content: "noindex, nofollow" },
      { property: "og:title", content: "MINT.AI — Video" },
      { property: "og:description", content: "MINT.AI video." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: VideoPage,
});

function VideoPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-4">
      <video
        src={showreelAsset.url}
        controls
        autoPlay
        loop
        playsInline
        className="max-h-[92vh] w-full max-w-6xl rounded-xl border border-border shadow-2xl"
      />
    </main>
  );
}
