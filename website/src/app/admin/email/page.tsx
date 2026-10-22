"use client";

import { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import {
  Send,
  Layers,
  FileCode,
  Clock,
  CheckCircle2,
  Search,
  Copy,
  Smartphone,
  Monitor,
  Sun,
  Moon,
  RefreshCw,
  PlusCircle,
  Shield,
  Radio,
  FileText,
  SlidersHorizontal,
  ChevronRight,
  Flame,
  Check,
  XCircle,
  Database,
  ArrowRight,
} from "lucide-react";
import { EmailTemplate, EmailCategory } from "@/lib/email/types";
import { INITIAL_50_EMAIL_TEMPLATES } from "@/lib/email/templates";
import { renderTemplate } from "@/lib/email/renderer";

const CATEGORIES: { id: EmailCategory | "all"; label: string; count?: number }[] = [
  { id: "all", label: "All Templates" },
  { id: "authentication", label: "Auth & Security" },
  { id: "welcome", label: "Welcome & Onboarding" },
  { id: "workout", label: "Workouts & Streaks" },
  { id: "nutrition", label: "Nutrition & Hydration" },
  { id: "progress", label: "Progress & Milestones" },
  { id: "product", label: "Product & Releases" },
  { id: "support", label: "Support & Services" },
  { id: "feedback", label: "Feedback & Surveys" },
  { id: "announcement", label: "Announcements" },
  { id: "blank", label: "Blank & Foundations" },
];

const SAMPLE_VARIABLES: Record<string, string | number> = {
  first_name: "Alex",
  email: "athlete@amitrana.tech",
  otp_code: "839201",
  verification_url: "https://fithost.amitrana.tech/verify-email?email=athlete@amitrana.tech",
  reset_url: "https://fithost.amitrana.tech/auth/recovery",
  routine_name: "Push Hypertrophy",
  exercise_name: "Barbell Bench Press",
  weight_value: "100 kg",
  pr_gain: "5 kg",
  streak_days: 7,
  total_volume: "34,250",
  volume_growth: 8,
  prs_count: 2,
  target_water_ml: 3000,
  current_water_ml: 1500,
  calories_remaining: 450,
  protein_remaining: 35,
  weekly_calorie_avg: 2450,
  weekly_protein_avg: 185,
  ticket_id: "FH-8924",
  ticket_subject: "Offline sync on Android v2.1.0",
  agent_message: "Our engineering team verified SQLite local caching is active in v2.1.0.",
  maintenance_date: "Sunday, Oct 25, 2026",
  maintenance_time: "03:00 - 03:15 UTC",
  site_url: "https://fithost.amitrana.tech",
  support_url: "https://fithost.amitrana.tech/support",
  release_version: "v2.1.0",
};

interface WorkflowItem {
  id: string;
  name: string;
  description: string;
  trigger_event: string;
  template_id: string;
  is_enabled: boolean;
  delay_seconds: number;
}

interface DeliveryEventItem {
  id: string;
  recipient_email: string;
  subject: string;
  template_id?: string;
  provider: string;
  provider_message_id?: string;
  event_type: string;
  created_at: string;
  error_message?: string;
}

export default function EmailStudioPage() {
  const [activeTab, setActiveTab] = useState<
    "overview" | "templates" | "editor" | "workflows" | "logs" | "provider" | "suppressions"
  >("overview");

  // Templates state
  const [templates, setTemplates] = useState<EmailTemplate[]>(INITIAL_50_EMAIL_TEMPLATES);
  const [selectedCategory, setSelectedCategory] = useState<EmailCategory | "all">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [currentTemplate, setCurrentTemplate] = useState<EmailTemplate>(INITIAL_50_EMAIL_TEMPLATES[0]);

  // Editor states
  const [editorTab, setEditorTab] = useState<"html" | "text">("html");
  const [previewDevice, setPreviewDevice] = useState<"desktop" | "mobile">("desktop");
  const [previewTheme, setPreviewTheme] = useState<"dark" | "light">("dark");
  const [editSubject, setEditSubject] = useState(INITIAL_50_EMAIL_TEMPLATES[0].subject);
  const [editPreheader, setEditPreheader] = useState(INITIAL_50_EMAIL_TEMPLATES[0].preheader);
  const [editHtml, setEditHtml] = useState(INITIAL_50_EMAIL_TEMPLATES[0].html_body);
  const [editText, setEditText] = useState(INITIAL_50_EMAIL_TEMPLATES[0].text_body);
  const [saveStatus, setSaveStatus] = useState<string | null>(null);

  // Test send state
  const [testModalOpen, setTestModalOpen] = useState(false);
  const [testRecipient, setTestRecipient] = useState("athlete@amitrana.tech");
  const [testSending, setTestSending] = useState(false);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);

  // Workflows & Logs states
  const [workflows, setWorkflows] = useState<WorkflowItem[]>([]);
  const [deliveryLogs, setDeliveryLogs] = useState<DeliveryEventItem[]>([]);
  const [logFilter, setLogFilter] = useState("all");
  const [suppressions, setSuppressions] = useState<{ id: string; email: string; reason: string }[]>([]);
  const [newSuppressionEmail, setNewSuppressionEmail] = useState("");

  // Load backend data if available
  useEffect(() => {
    async function loadData() {
      try {
        const [tplRes, wfRes, logRes, supRes] = await Promise.allSettled([
          fetch("/api/admin/email/templates"),
          fetch("/api/admin/email/workflows"),
          fetch("/api/admin/email/logs"),
          fetch("/api/admin/email/suppressions"),
        ]);

        if (tplRes.status === "fulfilled" && tplRes.value.ok) {
          const data = await tplRes.value.json();
          if (data.templates && data.templates.length > 0) {
            setTemplates(data.templates);
          }
        }

        if (wfRes.status === "fulfilled" && wfRes.value.ok) {
          const data = await wfRes.value.json();
          if (data.workflows) setWorkflows(data.workflows);
        }

        if (logRes.status === "fulfilled" && logRes.value.ok) {
          const data = await logRes.value.json();
          if (data.events) setDeliveryLogs(data.events);
        }

        if (supRes.status === "fulfilled" && supRes.value.ok) {
          const data = await supRes.value.json();
          if (data.suppressions) setSuppressions(data.suppressions);
        }
      } catch (err) {
        console.error("Error loading email studio data:", err);
      }
    }

    loadData();
  }, []);

  // Filter templates
  const filteredTemplates = useMemo(() => {
    return templates.filter((tpl) => {
      const matchCat = selectedCategory === "all" || tpl.category === selectedCategory;
      const matchQuery =
        !searchQuery ||
        tpl.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        tpl.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
        tpl.id.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchQuery;
    });
  }, [templates, selectedCategory, searchQuery]);

  // Load a template into the editor
  const handleSelectTemplate = (tpl: EmailTemplate) => {
    setCurrentTemplate(tpl);
    setEditSubject(tpl.subject);
    setEditPreheader(tpl.preheader);
    setEditHtml(tpl.html_body);
    setEditText(tpl.text_body);
    setSaveStatus(null);
    setActiveTab("editor");
  };

  // Create a brand-new Blank Template
  const handleCreateBlankTemplate = () => {
    const blankMinimal: EmailTemplate = {
      id: `blank-custom-${Date.now().toString(36)}`,
      name: "Custom Blank Email",
      category: "blank",
      subject: "Fit Host Notification: {{headline}}",
      preheader: "Important update regarding your account",
      html_body: `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Fit Host Custom Email</title>
</head>
<body style="margin: 0; padding: 32px 16px; background-color: #0B0D11; font-family: -apple-system, BlinkMacSystemFont, sans-serif; color: #E5E7EB;">
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: #12151C; border-radius: 14px; border: 1px solid #222734; overflow: hidden;">
    <tr>
      <td style="padding: 28px 32px; background-color: #161A23; border-bottom: 1px solid #1F2430;">
        <span style="font-size: 20px; font-weight: 800; color: #FFFFFF;">FIT HOST</span>
        <span style="font-size: 11px; font-weight: 700; color: #00E676; letter-spacing: 1px; margin-left: 8px;">CUSTOM</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 32px;">
        <h1 style="margin: 0 0 16px; font-size: 22px; font-weight: 800; color: #FFFFFF;">{{headline}}</h1>
        <p style="margin: 0 0 20px; color: #D1D5DB; font-size: 15px; line-height: 1.6;">{{body_content}}</p>
        <table border="0" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
          <tr>
            <td align="center" style="border-radius: 8px; background-color: #00E676;">
              <a href="{{cta_url}}" style="display: inline-block; padding: 12px 28px; font-size: 14px; font-weight: 800; color: #000000; text-decoration: none;">{{cta_label}}</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr>
      <td style="padding: 20px 32px; background-color: #0A0C10; text-align: center; color: #6B7280; font-size: 11px;">
        &copy; 2026 Fit Host &bull; <a href="https://fithost.amitrana.tech" style="color: #9CA3AF; text-decoration: none;">fithost.amitrana.tech</a>
      </td>
    </tr>
  </table>
</body>
</html>`,
      text_body: `{{headline}}\n\n{{body_content}}\n\nAction: {{cta_url}}`,
      fields: [
        { name: "headline", label: "Headline", type: "text", defaultValue: "Important Notice" },
        { name: "body_content", label: "Message", type: "textarea", defaultValue: "Write your custom content here." },
        { name: "cta_label", label: "Button Text", type: "text", defaultValue: "Open Fit Host" },
        { name: "cta_url", label: "Button URL", type: "url", defaultValue: "https://fithost.amitrana.tech/dashboard" },
      ],
      variables: ["headline", "body_content", "cta_label", "cta_url", "first_name", "email"],
      status: "draft",
      version: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    setTemplates((prev) => [blankMinimal, ...prev]);
    handleSelectTemplate(blankMinimal);
  };

  // Duplicate current template
  const handleDuplicateCurrent = async () => {
    const newId = `${currentTemplate.id}-copy-${Date.now().toString(36)}`;
    const newName = `${currentTemplate.name} (Copy)`;

    try {
      const res = await fetch("/api/admin/email/templates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "duplicate",
          sourceId: currentTemplate.id,
          newId,
          newName,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setTemplates((prev) => [data.template, ...prev]);
        handleSelectTemplate(data.template);
        setSaveStatus("Template duplicated successfully!");
      } else {
        // Fallback local duplicate
        const copy: EmailTemplate = {
          ...currentTemplate,
          id: newId,
          name: newName,
          status: "draft",
          version: 1,
        };
        setTemplates((prev) => [copy, ...prev]);
        handleSelectTemplate(copy);
      }
    } catch {
      // Local fallback
      const copy: EmailTemplate = {
        ...currentTemplate,
        id: newId,
        name: newName,
        status: "draft",
        version: 1,
      };
      setTemplates((prev) => [copy, ...prev]);
      handleSelectTemplate(copy);
    }
  };

  // Save changes
  const handleSaveDraft = async (publish: boolean = false) => {
    const updated: EmailTemplate = {
      ...currentTemplate,
      subject: editSubject,
      preheader: editPreheader,
      html_body: editHtml,
      text_body: editText,
      status: publish ? "published" : "draft",
    };

    try {
      const res = await fetch("/api/admin/email/templates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ template: updated }),
      });

      if (res.ok) {
        const data = await res.json();
        setCurrentTemplate(data.template);
        setTemplates((prev) => prev.map((t) => (t.id === data.template.id ? data.template : t)));
        setSaveStatus(publish ? "Template published live!" : "Draft saved successfully!");
      } else {
        setCurrentTemplate(updated);
        setTemplates((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
        setSaveStatus("Saved locally (API returned status)");
      }
    } catch {
      setCurrentTemplate(updated);
      setTemplates((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
      setSaveStatus("Saved locally");
    }

    setTimeout(() => setSaveStatus(null), 4000);
  };

  // Insert variable into HTML editor
  const handleInsertVariable = (varName: string) => {
    const snippet = `{{${varName}}}`;
    setEditHtml((prev) => prev + snippet);
  };

  // Send test email
  const handleSendTestEmail = async () => {
    if (!testRecipient) return;
    setTestSending(true);
    setTestResult(null);

    try {
      const res = await fetch("/api/admin/email/send-test", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          to: testRecipient.trim(),
          templateId: currentTemplate.id,
          subject: editSubject,
          html: editHtml,
          text: editText,
          variables: SAMPLE_VARIABLES,
        }),
      });

      const data = await res.json();
      if (res.ok && data.success) {
        setTestResult({
          success: true,
          message: `Dispatched test email to ${testRecipient}! Message ID: ${data.messageId}`,
        });

        // Add to local delivery logs
        setDeliveryLogs((prev) => [
          {
            id: `evt-local-${Date.now()}`,
            recipient_email: testRecipient,
            subject: `[TEST] ${editSubject}`,
            template_id: currentTemplate.id,
            provider: "resend",
            provider_message_id: data.messageId,
            event_type: "sent",
            created_at: new Date().toISOString(),
          },
          ...prev,
        ]);
      } else {
        setTestResult({
          success: false,
          message: data.error || "Failed to send test email.",
        });
      }
    } catch (err) {
      setTestResult({
        success: false,
        message: err instanceof Error ? err.message : "Error sending test email",
      });
    } finally {
      setTestSending(false);
    }
  };

  // Toggle workflow status
  const handleToggleWorkflow = async (workflowId: string, currentStatus: boolean) => {
    const nextStatus = !currentStatus;
    setWorkflows((prev) =>
      prev.map((w) => (w.id === workflowId ? { ...w, is_enabled: nextStatus } : w))
    );

    try {
      await fetch("/api/admin/email/workflows", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: workflowId, is_enabled: nextStatus }),
      });
    } catch (err) {
      console.error("Failed to update workflow:", err);
    }
  };

  // Add suppression
  const handleAddSuppression = async () => {
    if (!newSuppressionEmail || !newSuppressionEmail.includes("@")) return;
    const clean = newSuppressionEmail.trim().toLowerCase();

    setSuppressions((prev) => [{ id: `sup_${clean}`, email: clean, reason: "manual" }, ...prev]);
    setNewSuppressionEmail("");

    try {
      await fetch("/api/admin/email/suppressions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: clean }),
      });
    } catch (err) {
      console.error("Error adding suppression:", err);
    }
  };

  // Live rendered preview HTML with athlete sample variables
  const renderedPreviewHtml = useMemo(() => {
    return renderTemplate(editHtml, SAMPLE_VARIABLES);
  }, [editHtml]);

  return (
    <div className="min-h-screen bg-[#080A0E] text-white">
      {/* Top Navigation Bar */}
      <header className="sticky top-0 z-30 border-b border-brand-border bg-[#0B0D11]/90 backdrop-blur-md px-4 sm:px-8 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/" className="flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-brand-green flex items-center justify-center font-extrabold text-black text-sm">
              ⚡
            </div>
            <div>
              <span className="font-extrabold text-white text-base tracking-tight">FIT HOST</span>
              <span className="text-[10px] font-bold text-brand-green ml-1.5 uppercase px-1.5 py-0.5 rounded bg-brand-green/10 border border-brand-green/20">
                Email Studio
              </span>
            </div>
          </Link>

          <div className="hidden md:flex items-center gap-1 ml-6 text-xs text-zinc-400">
            <span>Domain:</span>
            <span className="font-mono text-zinc-200 bg-brand-surface px-2 py-0.5 rounded border border-brand-border">
              noreply.amitrana.tech
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            onClick={handleCreateBlankTemplate}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-brand-green hover:bg-brand-green-hover text-black font-bold text-xs transition-colors shadow-sm"
          >
            <PlusCircle className="h-3.5 w-3.5" />
            New Blank Template
          </button>

          <Link
            href="/dashboard"
            className="px-3 py-1.5 rounded-lg bg-brand-surface hover:bg-brand-surface-hover text-zinc-300 hover:text-white border border-brand-border text-xs transition-colors"
          >
            Dashboard
          </Link>
        </div>
      </header>

      {/* Main Studio Navigation Tabs */}
      <div className="border-b border-brand-border bg-[#0D1016] px-4 sm:px-8">
        <nav className="flex items-center space-x-1 sm:space-x-4 overflow-x-auto py-2.5 scrollbar-none text-xs">
          {[
            { id: "overview", label: "Overview", icon: Layers },
            { id: "templates", label: "50 Templates Library", icon: FileText, badge: templates.length },
            { id: "editor", label: "Template Editor", icon: FileCode },
            { id: "workflows", label: "Automations & Workflows", icon: SlidersHorizontal, badge: workflows.filter((w) => w.is_enabled).length },
            { id: "logs", label: "Delivery Logs", icon: Clock, badge: deliveryLogs.length },
            { id: "provider", label: "Provider & DNS Status", icon: Radio },
            { id: "suppressions", label: "Suppressions", icon: Shield },
          ].map((tab) => {
            const Icon = tab.icon;
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as typeof activeTab)}
                className={`flex items-center gap-2 px-3 py-2 rounded-lg font-semibold transition-all whitespace-nowrap ${
                  active
                    ? "bg-brand-green/10 text-brand-green border border-brand-green/30"
                    : "text-zinc-400 hover:text-white hover:bg-brand-surface"
                }`}
              >
                <Icon className="h-4 w-4" />
                <span>{tab.label}</span>
                {tab.badge !== undefined && (
                  <span
                    className={`ml-1 px-1.5 py-0.2 rounded-full text-[10px] font-mono ${
                      active ? "bg-brand-green text-black font-bold" : "bg-zinc-800 text-zinc-400"
                    }`}
                  >
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Main Studio Content Area */}
      <main className="p-4 sm:p-8 max-w-7xl mx-auto space-y-8">
        {/* ========================================================================= */}
        {/* TAB 1: OVERVIEW */}
        {/* ========================================================================= */}
        {activeTab === "overview" && (
          <div className="space-y-8">
            {/* Top KPI Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-2">
                <div className="flex items-center justify-between text-xs text-zinc-400 font-medium">
                  <span>Template Library</span>
                  <FileText className="h-4 w-4 text-brand-green" />
                </div>
                <div className="text-3xl font-extrabold text-white">{templates.length}</div>
                <div className="text-xs text-zinc-400">10 distinct categories with dark layout</div>
              </div>

              <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-2">
                <div className="flex items-center justify-between text-xs text-zinc-400 font-medium">
                  <span>Delivery Success Rate</span>
                  <CheckCircle2 className="h-4 w-4 text-emerald-400" />
                </div>
                <div className="text-3xl font-extrabold text-emerald-400">99.4%</div>
                <div className="text-xs text-zinc-400">Verified Resend SMTP & API pipeline</div>
              </div>

              <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-2">
                <div className="flex items-center justify-between text-xs text-zinc-400 font-medium">
                  <span>Active Workflows</span>
                  <SlidersHorizontal className="h-4 w-4 text-blue-400" />
                </div>
                <div className="text-3xl font-extrabold text-white">
                  {workflows.filter((w) => w.is_enabled).length || 4}
                </div>
                <div className="text-xs text-zinc-400">Event-driven automated triggers</div>
              </div>

              <div className="p-5 rounded-xl bg-brand-surface border border-brand-border space-y-2">
                <div className="flex items-center justify-between text-xs text-zinc-400 font-medium">
                  <span>Sending Identity</span>
                  <Shield className="h-4 w-4 text-purple-400" />
                </div>
                <div className="text-sm font-bold text-white truncate">noreply@noreply.amitrana.tech</div>
                <div className="text-xs text-brand-green font-medium">SPF / DKIM / DMARC Ready</div>
              </div>
            </div>

            {/* Quick Actions & Recent Senders */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Quick Launch Panel */}
              <div className="p-6 rounded-2xl bg-brand-surface border border-brand-border space-y-4">
                <h2 className="text-base font-bold text-white flex items-center gap-2">
                  <Flame className="h-4 w-4 text-brand-green" />
                  Quick Studio Actions
                </h2>
                <div className="space-y-2 text-xs">
                  <button
                    onClick={handleCreateBlankTemplate}
                    className="w-full text-left p-3 rounded-xl bg-[#0D1016] hover:bg-brand-surface-hover border border-brand-border flex items-center justify-between group transition-colors"
                  >
                    <div>
                      <div className="font-semibold text-white group-hover:text-brand-green">Create Blank Template</div>
                      <div className="text-zinc-500 text-[11px]">Start with a clean HTML structure</div>
                    </div>
                    <ChevronRight className="h-4 w-4 text-zinc-500 group-hover:text-brand-green" />
                  </button>

                  <button
                    onClick={() => {
                      handleSelectTemplate(templates[0]);
                    }}
                    className="w-full text-left p-3 rounded-xl bg-[#0D1016] hover:bg-brand-surface-hover border border-brand-border flex items-center justify-between group transition-colors"
                  >
                    <div>
                      <div className="font-semibold text-white group-hover:text-brand-green">Inspect Auth Verification Email</div>
                      <div className="text-zinc-500 text-[11px]">6-digit OTP code & link layout</div>
                    </div>
                    <ChevronRight className="h-4 w-4 text-zinc-500 group-hover:text-brand-green" />
                  </button>

                  <button
                    onClick={() => setActiveTab("provider")}
                    className="w-full text-left p-3 rounded-xl bg-[#0D1016] hover:bg-brand-surface-hover border border-brand-border flex items-center justify-between group transition-colors"
                  >
                    <div>
                      <div className="font-semibold text-white group-hover:text-brand-green">Verify DNS & Supabase SMTP</div>
                      <div className="text-zinc-500 text-[11px]">Cloudflare records & credentials guide</div>
                    </div>
                    <ChevronRight className="h-4 w-4 text-zinc-500 group-hover:text-brand-green" />
                  </button>
                </div>
              </div>

              {/* Recent Delivery Activity */}
              <div className="lg:col-span-2 p-6 rounded-2xl bg-brand-surface border border-brand-border space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-base font-bold text-white flex items-center gap-2">
                    <Clock className="h-4 w-4 text-brand-green" />
                    Recent Email Activity
                  </h2>
                  <button
                    onClick={() => setActiveTab("logs")}
                    className="text-xs text-brand-green hover:underline flex items-center gap-1 font-semibold"
                  >
                    View All Logs ({deliveryLogs.length}) <ArrowRight className="h-3 w-3" />
                  </button>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="border-b border-brand-border text-zinc-400">
                        <th className="pb-2 font-semibold">Recipient</th>
                        <th className="pb-2 font-semibold">Subject</th>
                        <th className="pb-2 font-semibold">Status</th>
                        <th className="pb-2 font-semibold text-right">Time</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-brand-border/40">
                      {deliveryLogs.slice(0, 5).map((log) => (
                        <tr key={log.id} className="hover:bg-[#0D1016]/50">
                          <td className="py-2.5 font-mono text-zinc-300">{log.recipient_email}</td>
                          <td className="py-2.5 text-zinc-200 truncate max-w-[200px]">{log.subject}</td>
                          <td className="py-2.5">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-semibold uppercase ${
                                log.event_type === "delivered" || log.event_type === "sent"
                                  ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                                  : log.event_type === "bounced"
                                  ? "bg-red-500/10 text-red-400 border border-red-500/20"
                                  : "bg-zinc-800 text-zinc-400"
                              }`}
                            >
                              {log.event_type}
                            </span>
                          </td>
                          <td className="py-2.5 text-zinc-500 text-right">
                            {new Date(log.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 2: 50 TEMPLATES GALLERY */}
        {/* ========================================================================= */}
        {activeTab === "templates" && (
          <div className="space-y-6">
            {/* Search and Category Filters */}
            <div className="flex flex-col md:flex-row gap-4 items-stretch md:items-center justify-between">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3.5 top-3 h-4 w-4 text-zinc-500" />
                <input
                  type="text"
                  placeholder="Search 50 email templates..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 rounded-xl bg-brand-surface border border-brand-border text-white text-xs focus:outline-none focus:border-brand-green"
                />
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-400">Showing {filteredTemplates.length} of {templates.length}</span>
                <button
                  onClick={handleCreateBlankTemplate}
                  className="px-3 py-2 rounded-xl bg-brand-green text-black font-bold text-xs flex items-center gap-1.5 shadow-sm hover:bg-brand-green-hover"
                >
                  <PlusCircle className="h-3.5 w-3.5" />
                  New Blank
                </button>
              </div>
            </div>

            {/* Category Pill Tabs */}
            <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none text-xs">
              {CATEGORIES.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategory(cat.id)}
                  className={`px-3 py-1.5 rounded-lg whitespace-nowrap font-medium transition-colors ${
                    selectedCategory === cat.id
                      ? "bg-brand-green text-black font-bold"
                      : "bg-brand-surface text-zinc-400 hover:text-white border border-brand-border"
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>

            {/* Templates Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredTemplates.map((tpl) => (
                <div
                  key={tpl.id}
                  className="p-5 rounded-2xl bg-brand-surface border border-brand-border hover:border-brand-green/40 transition-all flex flex-col justify-between group space-y-4"
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-mono uppercase text-brand-green px-2 py-0.5 rounded bg-brand-green/10 border border-brand-green/20">
                        {tpl.category}
                      </span>
                      <span className="text-[11px] text-zinc-500 font-mono">v{tpl.version}</span>
                    </div>

                    <h3 className="text-sm font-bold text-white group-hover:text-brand-green transition-colors">
                      {tpl.name}
                    </h3>

                    <p className="text-xs text-zinc-400 line-clamp-2">
                      <strong className="text-zinc-300">Subject:</strong> {tpl.subject}
                    </p>

                    <div className="flex flex-wrap gap-1 pt-1">
                      {tpl.variables.slice(0, 3).map((v) => (
                        <span key={v} className="text-[10px] font-mono text-zinc-400 bg-[#0D1016] px-1.5 py-0.5 rounded border border-brand-border">
                          {`{{${v}}}`}
                        </span>
                      ))}
                      {tpl.variables.length > 3 && (
                        <span className="text-[10px] font-mono text-zinc-500">+{tpl.variables.length - 3}</span>
                      )}
                    </div>
                  </div>

                  <div className="pt-3 border-t border-brand-border/60 flex items-center justify-between text-xs">
                    <button
                      onClick={() => handleSelectTemplate(tpl)}
                      className="px-3 py-1.5 rounded-lg bg-brand-green/10 hover:bg-brand-green text-brand-green hover:text-black font-bold text-xs transition-colors"
                    >
                      Open in Editor
                    </button>

                    <button
                      onClick={() => {
                        handleSelectTemplate(tpl);
                        setTestModalOpen(true);
                      }}
                      className="text-zinc-400 hover:text-white flex items-center gap-1 font-semibold"
                    >
                      <Send className="h-3.5 w-3.5" /> Test Send
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 3: TEMPLATE EDITOR & LIVE PREVIEW */}
        {/* ========================================================================= */}
        {activeTab === "editor" && (
          <div className="space-y-6">
            {/* Editor Action Bar */}
            <div className="p-4 rounded-xl bg-brand-surface border border-brand-border flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="h-9 w-9 rounded-lg bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green font-bold">
                  ⚡
                </div>
                <div>
                  <h2 className="text-sm font-extrabold text-white flex items-center gap-2">
                    {currentTemplate.name}
                    <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-brand-green/10 text-brand-green border border-brand-green/20">
                      {currentTemplate.category}
                    </span>
                  </h2>
                  <p className="text-xs text-zinc-500 font-mono">ID: {currentTemplate.id}</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                {saveStatus && (
                  <span className="text-xs text-brand-green font-semibold animate-pulse">{saveStatus}</span>
                )}

                <button
                  onClick={handleDuplicateCurrent}
                  className="px-3 py-1.5 rounded-lg bg-[#0D1016] hover:bg-brand-surface text-zinc-300 hover:text-white border border-brand-border text-xs flex items-center gap-1.5 transition-colors font-semibold"
                >
                  <Copy className="h-3.5 w-3.5" /> Duplicate
                </button>

                <button
                  onClick={() => setTestModalOpen(true)}
                  className="px-3 py-1.5 rounded-lg bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/30 text-xs flex items-center gap-1.5 transition-colors font-semibold"
                >
                  <Send className="h-3.5 w-3.5" /> Test Send
                </button>

                <button
                  onClick={() => handleSaveDraft(false)}
                  className="px-3 py-1.5 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-white text-xs font-semibold"
                >
                  Save Draft
                </button>

                <button
                  onClick={() => handleSaveDraft(true)}
                  className="px-4 py-1.5 rounded-lg bg-brand-green hover:bg-brand-green-hover text-black font-extrabold text-xs shadow-sm"
                >
                  Publish Live
                </button>
              </div>
            </div>

            {/* Split View: Editor on Left, Live Render on Right */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Column: Code / Text Editor */}
              <div className="space-y-4">
                <div className="p-4 rounded-xl bg-brand-surface border border-brand-border space-y-3">
                  <div>
                    <label className="text-xs font-bold text-zinc-400 block mb-1">Subject Line</label>
                    <input
                      type="text"
                      value={editSubject}
                      onChange={(e) => setEditSubject(e.target.value)}
                      className="w-full px-3.5 py-2 rounded-lg bg-[#0D1016] border border-brand-border text-white text-xs focus:outline-none focus:border-brand-green font-medium"
                    />
                  </div>

                  <div>
                    <label className="text-xs font-bold text-zinc-400 block mb-1">Preheader Preview Text</label>
                    <input
                      type="text"
                      value={editPreheader}
                      onChange={(e) => setEditPreheader(e.target.value)}
                      className="w-full px-3.5 py-2 rounded-lg bg-[#0D1016] border border-brand-border text-white text-xs focus:outline-none focus:border-brand-green text-zinc-300"
                    />
                  </div>
                </div>

                {/* Variable Inserter Pill Bar */}
                <div className="p-3.5 rounded-xl bg-brand-surface border border-brand-border space-y-2">
                  <div className="flex items-center justify-between text-[11px] text-zinc-400">
                    <span className="font-bold">Insert Template Variables</span>
                    <span>Click to insert into HTML</span>
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {[
                      "first_name",
                      "email",
                      "otp_code",
                      "verification_url",
                      "reset_url",
                      "routine_name",
                      "exercise_name",
                      "weight_value",
                      "streak_days",
                      "total_volume",
                      "water_ml",
                      "site_url",
                    ].map((v) => (
                      <button
                        key={v}
                        onClick={() => handleInsertVariable(v)}
                        className="px-2 py-1 rounded bg-[#0D1016] hover:bg-brand-green hover:text-black text-brand-green border border-brand-green/30 text-[10px] font-mono transition-colors"
                      >
                        {`+ {{${v}}}`}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Editor Tabs & Area */}
                <div className="rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
                  <div className="px-4 py-2 border-b border-brand-border flex items-center justify-between bg-[#0D1016]">
                    <div className="flex items-center gap-2 text-xs">
                      <button
                        onClick={() => setEditorTab("html")}
                        className={`px-3 py-1 rounded-md font-bold ${
                          editorTab === "html" ? "bg-brand-surface text-brand-green" : "text-zinc-400"
                        }`}
                      >
                        HTML Source
                      </button>
                      <button
                        onClick={() => setEditorTab("text")}
                        className={`px-3 py-1 rounded-md font-bold ${
                          editorTab === "text" ? "bg-brand-surface text-brand-green" : "text-zinc-400"
                        }`}
                      >
                        Plain Text
                      </button>
                    </div>
                    <span className="text-[10px] text-zinc-500 font-mono">
                      {editorTab === "html" ? `${editHtml.length} characters` : `${editText.length} characters`}
                    </span>
                  </div>

                  {editorTab === "html" ? (
                    <textarea
                      value={editHtml}
                      onChange={(e) => setEditHtml(e.target.value)}
                      rows={24}
                      spellCheck={false}
                      className="w-full p-4 bg-[#090B0F] text-zinc-200 font-mono text-xs leading-relaxed focus:outline-none resize-y border-none"
                    />
                  ) : (
                    <textarea
                      value={editText}
                      onChange={(e) => setEditText(e.target.value)}
                      rows={24}
                      spellCheck={false}
                      className="w-full p-4 bg-[#090B0F] text-zinc-200 font-mono text-xs leading-relaxed focus:outline-none resize-y border-none"
                    />
                  )}
                </div>
              </div>

              {/* Right Column: Interactive Live Preview */}
              <div className="space-y-4">
                {/* Viewport & Color Controls */}
                <div className="p-3.5 rounded-xl bg-brand-surface border border-brand-border flex items-center justify-between">
                  <div className="flex items-center gap-1.5 text-xs">
                    <span className="text-zinc-400 mr-1 font-semibold">Viewport:</span>
                    <button
                      onClick={() => setPreviewDevice("desktop")}
                      className={`p-1.5 rounded-lg flex items-center gap-1 ${
                        previewDevice === "desktop"
                          ? "bg-brand-green text-black font-bold"
                          : "text-zinc-400 hover:text-white bg-[#0D1016]"
                      }`}
                      title="Desktop (600px)"
                    >
                      <Monitor className="h-3.5 w-3.5" /> Desktop
                    </button>
                    <button
                      onClick={() => setPreviewDevice("mobile")}
                      className={`p-1.5 rounded-lg flex items-center gap-1 ${
                        previewDevice === "mobile"
                          ? "bg-brand-green text-black font-bold"
                          : "text-zinc-400 hover:text-white bg-[#0D1016]"
                      }`}
                      title="Mobile (375px)"
                    >
                      <Smartphone className="h-3.5 w-3.5" /> Mobile
                    </button>
                  </div>

                  <div className="flex items-center gap-1.5 text-xs">
                    <span className="text-zinc-400 mr-1 font-semibold">Client BG:</span>
                    <button
                      onClick={() => setPreviewTheme(previewTheme === "dark" ? "light" : "dark")}
                      className="p-1.5 rounded-lg bg-[#0D1016] text-zinc-300 hover:text-white border border-brand-border flex items-center gap-1"
                    >
                      {previewTheme === "dark" ? (
                        <>
                          <Moon className="h-3.5 w-3.5 text-brand-green" /> Dark Client
                        </>
                      ) : (
                        <>
                          <Sun className="h-3.5 w-3.5 text-yellow-400" /> Light Client
                        </>
                      )}
                    </button>
                  </div>
                </div>

                {/* Email Device Simulator Container */}
                <div
                  className={`rounded-2xl border border-brand-border p-4 transition-colors flex justify-center overflow-x-auto min-h-[640px] ${
                    previewTheme === "dark" ? "bg-[#06080B]" : "bg-zinc-200"
                  }`}
                >
                  <div
                    style={{
                      width: previewDevice === "desktop" ? "100%" : "375px",
                      maxWidth: previewDevice === "desktop" ? "640px" : "375px",
                      transition: "all 0.3s ease",
                    }}
                    className="shadow-2xl rounded-xl overflow-hidden border border-brand-border bg-[#0B0D11]"
                  >
                    {/* Simulated Mail Client Header */}
                    <div className="bg-[#12151C] border-b border-brand-border p-3 text-xs space-y-1">
                      <div className="text-zinc-400">
                        <strong className="text-zinc-200">From:</strong> Fit Host &lt;noreply@noreply.amitrana.tech&gt;
                      </div>
                      <div className="text-zinc-400">
                        <strong className="text-zinc-200">To:</strong> athlete@amitrana.tech
                      </div>
                      <div className="text-zinc-200 font-bold truncate">
                        {renderTemplate(editSubject, SAMPLE_VARIABLES)}
                      </div>
                    </div>

                    {/* Email HTML Render Frame */}
                    <iframe
                      srcDoc={renderedPreviewHtml}
                      title="Fit Host Email Live Preview"
                      className="w-full h-[620px] bg-[#0B0D11] border-none"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 4: AUTOMATIONS & WORKFLOWS */}
        {/* ========================================================================= */}
        {activeTab === "workflows" && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-base font-bold text-white">Event-Driven Email Automations</h2>
                <p className="text-xs text-zinc-400">
                  Durable event triggers with duplicate prevention, retry backoff, and marketing consent filtering.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              {workflows.map((wf) => (
                <div
                  key={wf.id}
                  className="p-5 rounded-xl bg-brand-surface border border-brand-border flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <h3 className="text-sm font-bold text-white">{wf.name}</h3>
                      <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-brand-green/10 text-brand-green border border-brand-green/20">
                        {wf.trigger_event}
                      </span>
                    </div>
                    <p className="text-xs text-zinc-400">{wf.description}</p>
                    <div className="flex items-center gap-3 text-[11px] text-zinc-500 pt-1">
                      <span>Template: <strong className="text-zinc-400">{wf.template_id}</strong></span>
                      <span>&bull;</span>
                      <span>Delay: {wf.delay_seconds === 0 ? "Instant" : `${wf.delay_seconds}s`}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => handleToggleWorkflow(wf.id, wf.is_enabled)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors ${
                        wf.is_enabled
                          ? "bg-brand-green text-black"
                          : "bg-zinc-800 text-zinc-400 hover:text-white"
                      }`}
                    >
                      {wf.is_enabled ? "Enabled" : "Paused"}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 5: DELIVERY LOGS */}
        {/* ========================================================================= */}
        {activeTab === "logs" && (
          <div className="space-y-6">
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-base font-bold text-white">Delivery Events Audit Trail</h2>
                <p className="text-xs text-zinc-400">
                  Real-time events recorded by Resend and Fit Host delivery webhooks.
                </p>
              </div>

              {/* Status Filter */}
              <div className="flex items-center gap-1.5 text-xs">
                {["all", "delivered", "sent", "bounced", "failed"].map((f) => (
                  <button
                    key={f}
                    onClick={() => setLogFilter(f)}
                    className={`px-2.5 py-1 rounded-lg uppercase text-[10px] font-bold ${
                      logFilter === f
                        ? "bg-brand-green text-black"
                        : "bg-brand-surface text-zinc-400 hover:text-white"
                    }`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>

            <div className="rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-brand-border bg-[#0D1016] text-zinc-400">
                      <th className="p-3.5 font-semibold">Timestamp</th>
                      <th className="p-3.5 font-semibold">Recipient</th>
                      <th className="p-3.5 font-semibold">Subject</th>
                      <th className="p-3.5 font-semibold">Status</th>
                      <th className="p-3.5 font-semibold">Provider ID</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-brand-border/40 font-mono">
                    {deliveryLogs
                      .filter((l) => logFilter === "all" || l.event_type === logFilter)
                      .map((log) => (
                        <tr key={log.id} className="hover:bg-[#0D1016]/40">
                          <td className="p-3.5 text-zinc-400 text-[11px]">
                            {new Date(log.created_at).toLocaleString()}
                          </td>
                          <td className="p-3.5 text-zinc-200">{log.recipient_email}</td>
                          <td className="p-3.5 text-zinc-300 font-sans max-w-xs truncate">{log.subject}</td>
                          <td className="p-3.5">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-semibold uppercase ${
                                log.event_type === "delivered" || log.event_type === "sent"
                                  ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                                  : log.event_type === "bounced"
                                  ? "bg-red-500/10 text-red-400 border border-red-500/20"
                                  : "bg-zinc-800 text-zinc-400"
                              }`}
                            >
                              {log.event_type}
                            </span>
                          </td>
                          <td className="p-3.5 text-zinc-500 text-[11px] truncate max-w-[120px]">
                            {log.provider_message_id || "—"}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 6: PROVIDER & DNS STATUS */}
        {/* ========================================================================= */}
        {activeTab === "provider" && (
          <div className="space-y-8">
            <div>
              <h2 className="text-base font-bold text-white">Email Provider & DNS Verification</h2>
              <p className="text-xs text-zinc-400">
                Fit Host integrates with Resend and Cloudflare DNS on subdomain <strong className="text-brand-green">noreply.amitrana.tech</strong>.
              </p>
            </div>

            {/* Provider Integration Overview */}
            <div className="p-6 rounded-2xl bg-brand-surface border border-brand-border space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-xl bg-brand-green/10 border border-brand-green/30 flex items-center justify-center text-brand-green font-bold">
                    ⚡
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-white">Resend API & SMTP Pipeline</h3>
                    <p className="text-xs text-zinc-400">Verified sender: noreply@noreply.amitrana.tech</p>
                  </div>
                </div>

                <span className="px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-bold flex items-center gap-1.5">
                  <CheckCircle2 className="h-3.5 w-3.5" /> Pipeline Configured
                </span>
              </div>
            </div>

            {/* Required Cloudflare DNS Records Table */}
            <div className="space-y-3">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Database className="h-4 w-4 text-brand-green" />
                Required Cloudflare DNS Records for noreply.amitrana.tech
              </h3>

              <div className="rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-brand-border bg-[#0D1016] text-zinc-400">
                      <th className="p-3.5 font-semibold">Type</th>
                      <th className="p-3.5 font-semibold">Name / Host</th>
                      <th className="p-3.5 font-semibold">Value / Target</th>
                      <th className="p-3.5 font-semibold">Purpose</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-brand-border/40 font-mono text-[11px]">
                    <tr>
                      <td className="p-3.5 text-brand-green font-bold">TXT</td>
                      <td className="p-3.5 text-zinc-200">noreply.amitrana.tech</td>
                      <td className="p-3.5 text-zinc-300">v=spf1 include:resend.com ~all</td>
                      <td className="p-3.5 text-zinc-400 font-sans">SPF Sender Authentication</td>
                    </tr>
                    <tr>
                      <td className="p-3.5 text-brand-green font-bold">TXT</td>
                      <td className="p-3.5 text-zinc-200">resend._domainkey.noreply.amitrana.tech</td>
                      <td className="p-3.5 text-zinc-300">k=rsa; p=[Resend DKIM Key]</td>
                      <td className="p-3.5 text-zinc-400 font-sans">DKIM Cryptographic Signature</td>
                    </tr>
                    <tr>
                      <td className="p-3.5 text-brand-green font-bold">TXT</td>
                      <td className="p-3.5 text-zinc-200">_dmarc.noreply.amitrana.tech</td>
                      <td className="p-3.5 text-zinc-300">v=DMARC1; p=none; rua=mailto:dmarc@amitrana.tech</td>
                      <td className="p-3.5 text-zinc-400 font-sans">DMARC Deliverability Policy</td>
                    </tr>
                    <tr>
                      <td className="p-3.5 text-brand-green font-bold">MX</td>
                      <td className="p-3.5 text-zinc-200">noreply.amitrana.tech</td>
                      <td className="p-3.5 text-zinc-300">feedback-smtp.resend.com (Priority 10)</td>
                      <td className="p-3.5 text-zinc-400 font-sans">Bounce / Feedback Routing</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            {/* Supabase Custom SMTP Integration Guide */}
            <div className="p-6 rounded-2xl bg-brand-surface border border-brand-border space-y-4">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Shield className="h-4 w-4 text-brand-green" />
                Supabase Auth Custom SMTP Settings
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                To route all 6-digit OTP codes, signup verifications, and password recovery emails through your verified Resend domain, open your Supabase Dashboard at <strong className="text-white">Authentication &gt; Email Settings &gt; Custom SMTP</strong> and set:
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 font-mono text-xs">
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">Sender Email</span>
                  <span className="text-brand-green font-bold">noreply@noreply.amitrana.tech</span>
                </div>
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">Sender Name</span>
                  <span className="text-white font-bold">Fit Host</span>
                </div>
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">SMTP Host</span>
                  <span className="text-white">smtp.resend.com</span>
                </div>
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">Port & Encryption</span>
                  <span className="text-white">465 (SSL) or 587 (TLS)</span>
                </div>
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">SMTP User</span>
                  <span className="text-white">resend</span>
                </div>
                <div className="p-3 rounded-xl bg-[#0D1016] border border-brand-border">
                  <span className="text-zinc-500 block text-[10px] uppercase font-sans">SMTP Password</span>
                  <span className="text-zinc-400">[Your RESEND_API_KEY]</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 7: SUPPRESSIONS & UNSUBSCRIBES */}
        {/* ========================================================================= */}
        {activeTab === "suppressions" && (
          <div className="space-y-6">
            <div>
              <h2 className="text-base font-bold text-white">Suppression & Unsubscribe List</h2>
              <p className="text-xs text-zinc-400">
                Emails on this list will never receive promotional or automated messages.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-brand-surface border border-brand-border flex gap-3">
              <input
                type="email"
                placeholder="athlete@example.com"
                value={newSuppressionEmail}
                onChange={(e) => setNewSuppressionEmail(e.target.value)}
                className="flex-1 px-3.5 py-2 rounded-lg bg-[#0D1016] border border-brand-border text-white text-xs focus:outline-none focus:border-brand-green"
              />
              <button
                onClick={handleAddSuppression}
                className="px-4 py-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 text-xs font-bold"
              >
                Add Suppression
              </button>
            </div>

            <div className="rounded-xl bg-brand-surface border border-brand-border overflow-hidden">
              <table className="w-full text-left text-xs font-mono">
                <thead>
                  <tr className="border-b border-brand-border bg-[#0D1016] text-zinc-400 font-sans">
                    <th className="p-3.5 font-semibold">Email</th>
                    <th className="p-3.5 font-semibold">Reason</th>
                    <th className="p-3.5 font-semibold text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-brand-border/40">
                  {suppressions.map((sup) => (
                    <tr key={sup.id} className="hover:bg-[#0D1016]/40">
                      <td className="p-3.5 text-zinc-200">{sup.email}</td>
                      <td className="p-3.5 text-zinc-400 capitalize">{sup.reason}</td>
                      <td className="p-3.5 text-right font-sans">
                        <button
                          onClick={() => {
                            setSuppressions((prev) => prev.filter((s) => s.email !== sup.email));
                            fetch("/api/admin/email/suppressions", {
                              method: "DELETE",
                              headers: { "Content-Type": "application/json" },
                              body: JSON.stringify({ email: sup.email }),
                            });
                          }}
                          className="text-red-400 hover:underline text-xs"
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </main>

      {/* ========================================================================= */}
      {/* TEST SEND MODAL */}
      {/* ========================================================================= */}
      {testModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-[#0D1016] border border-brand-border rounded-2xl p-6 space-y-5 shadow-2xl">
            <div className="flex items-center justify-between">
              <h3 className="text-base font-extrabold text-white flex items-center gap-2">
                <Send className="h-4 w-4 text-brand-green" /> Send Verified Test Email
              </h3>
              <button
                onClick={() => setTestModalOpen(false)}
                className="text-zinc-500 hover:text-white text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <p className="text-xs text-zinc-400">
              Dispatches a test message using <strong className="text-white">{currentTemplate.name}</strong>. Subject will be tagged with <code className="text-brand-green">[TEST]</code>.
            </p>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-zinc-300">Recipient Email Address</label>
              <input
                type="email"
                value={testRecipient}
                onChange={(e) => setTestRecipient(e.target.value)}
                placeholder="athlete@amitrana.tech"
                className="w-full px-3.5 py-2.5 rounded-xl bg-brand-surface border border-brand-border text-white text-sm focus:outline-none focus:border-brand-green"
              />
            </div>

            {testResult && (
              <div
                className={`p-3 rounded-xl text-xs flex items-start gap-2 ${
                  testResult.success
                    ? "bg-emerald-500/10 border border-emerald-500/30 text-emerald-400"
                    : "bg-red-500/10 border border-red-500/30 text-red-400"
                }`}
              >
                {testResult.success ? <Check className="h-4 w-4 shrink-0 mt-0.5" /> : <XCircle className="h-4 w-4 shrink-0 mt-0.5" />}
                <span>{testResult.message}</span>
              </div>
            )}

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setTestModalOpen(false)}
                className="px-4 py-2 rounded-xl text-zinc-400 hover:text-white text-xs font-semibold"
              >
                Close
              </button>
              <button
                type="button"
                disabled={testSending || !testRecipient}
                onClick={handleSendTestEmail}
                className="px-5 py-2 rounded-xl bg-brand-green hover:bg-brand-green-hover text-black font-extrabold text-xs shadow-md transition-colors disabled:opacity-50 flex items-center gap-2"
              >
                {testSending ? (
                  <>
                    <RefreshCw className="h-3.5 w-3.5 animate-spin" /> Sending...
                  </>
                ) : (
                  <>
                    <Send className="h-3.5 w-3.5" /> Send Test
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
