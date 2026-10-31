import { redirect } from "next/navigation";

export default function AdminEmailRedirectPage() {
  redirect("/admin?tab=email");
}
