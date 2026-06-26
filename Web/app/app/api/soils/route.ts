import { NextResponse } from "next/server";

export async function GET() {
  const soils = [
    { id: "sableux", nom: "Sableux" },
    { id: "limoneux", nom: "Limoneux" },
    { id: "argileux", nom: "Argileux" },
    { id: "sablo-limoneux", nom: "Sablo-limoneux" },
    { id: "argilo-limoneux", nom: "Argilo-limoneux" }
  ];

  return NextResponse.json(soils);
}
