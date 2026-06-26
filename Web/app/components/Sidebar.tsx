"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const links = [
  {
    label: "Dashboard",
    href: "/dashboard",
  },
  {
    label: "Farmers",
    href: "/farmers",
  },
  {
    label: "Plots",
    href: "/plots",
  },
 // {
    //label: "Weather",
    //href: "/weather",
  //}
  {
    label: "Recommendations",
    href: "/recommendations",
  },
  {
    label: "History",
    href: "/history",
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function handleLogout() {
    try {
      await fetch("/api/admin-logout", {
        method: "POST",
      });

      router.push("/login");
      router.refresh();
    } catch (error) {
      console.error("Logout error:", error);
      alert("Error during logout.");
    }
  }

  return (
    <aside className="sticky top-0 flex h-screen w-72 flex-col bg-emerald-950 px-6 py-8 text-white">
      <div>
        <h1 className="text-3xl font-bold">HydroSmart-MA</h1>
      </div>

      <nav className="mt-12 flex flex-1 flex-col gap-3">
        {links.map((link) => {
          const active = pathname === link.href;

          return (
            <Link
              key={link.href}
              href={link.href}
              className={`rounded-xl px-5 py-3 text-lg font-semibold transition ${
                active
                  ? "bg-emerald-600 text-white"
                  : "text-white hover:bg-emerald-800"
              }`}
            >
              {link.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-emerald-800 pt-5">
        <button
          onClick={handleLogout}
          className="w-full rounded-xl bg-red-500 px-5 py-3 text-left text-lg font-semibold text-white transition hover:bg-red-600"
        >
          Logout
        </button>
      </div>
    </aside>
  );
}