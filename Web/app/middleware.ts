import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const protectedRoutes = [
  "/dashboard",
  "/farmers",
  "/plots",
  "/weather",
  "/recommendations",
  "/history",
];

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  const isProtectedRoute = protectedRoutes.some((route) =>
    pathname.startsWith(route)
  );

  if (!isProtectedRoute) {
    return NextResponse.next();
  }

  const sessionCookie = request.cookies.get("admin_session")?.value;
  const sessionToken = process.env.ADMIN_SESSION_TOKEN;

  if (!sessionCookie || !sessionToken || sessionCookie !== sessionToken) {
    const loginUrl = new URL("/login", request.url);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/farmers/:path*",
    "/plots/:path*",
    "/weather/:path*",
    "/recommendations/:path*",
    "/history/:path*",
  ],
};