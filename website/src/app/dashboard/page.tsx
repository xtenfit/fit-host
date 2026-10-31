import { redirect } from "next/navigation";
import Image from "next/image";
import {
  Dumbbell,
  Droplets,
  Utensils,
  User,
  ShieldCheck,
  CalendarDays,
  TrendingUp,
  Activity,
} from "lucide-react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { isAuthorizedAdminEmail } from "@/lib/email/auth";
import SignOutButton from "@/components/dashboard/SignOutButton";
import AccountAppDownloadCard from "@/components/dashboard/AccountAppDownloadCard";

export const dynamic = "force-dynamic";

interface WorkoutSet {
  id?: string;
  set_number?: number;
  reps?: number;
  weight_kg?: number;
  rpe?: number;
  is_warmup?: boolean;
}

interface WorkoutExercise {
  id?: string;
  order_index?: number;
  workout_sets?: WorkoutSet[];
}

interface WorkoutRecord {
  id: string;
  title?: string;
  notes?: string;
  started_at?: string;
  completed_at?: string;
  duration_seconds?: number;
  created_at?: string;
  workout_exercises?: WorkoutExercise[];
}

interface HydrationRecord {
  id: string;
  amount_ml?: number;
  logged_at?: string;
  created_at?: string;
}

interface NutritionRecord {
  id: string;
  meal_type?: string;
  calories?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
  logged_at?: string;
  created_at?: string;
}

type DashboardRange = "today" | "week" | "month" | "custom" | "all";

interface DashboardSearchParams {
  range?: string;
  from?: string;
  to?: string;
}

function parseDate(value: string | undefined, fallback: Date) {
  if (!value) return fallback;
  const parsed = new Date(`${value}T00:00:00`);
  return Number.isNaN(parsed.getTime()) ? fallback : parsed;
}

function dateKey(value: string | undefined) {
  return value?.slice(0, 10) || "";
}

function formatDay(value: string) {
  return new Date(`${value}T00:00:00`).toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

export default async function DashboardPage({
  searchParams,
}: {
  searchParams?: Promise<DashboardSearchParams>;
}) {
  const supabase = await createClient();
  const params = (await searchParams) || {};
  const requestedRange = params.range as DashboardRange;
  const range: DashboardRange = ["today", "week", "month", "custom", "all"].includes(
    requestedRange,
  )
    ? requestedRange
    : "week";
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let fromDate = new Date(today);
  let toDate = new Date(today);
  toDate.setDate(toDate.getDate() + 1);
  if (range === "week") fromDate.setDate(fromDate.getDate() - 6);
  if (range === "month") fromDate = new Date(today.getFullYear(), today.getMonth(), 1);
  if (range === "custom") {
    fromDate = parseDate(params.from, today);
    toDate = parseDate(params.to, today);
    toDate.setDate(toDate.getDate() + 1);
  }
  if (range === "all") fromDate = new Date(2000, 0, 1);
  const rangeStart = fromDate.toISOString();
  const rangeEnd = toDate.toISOString();

  // 1. Verify authenticated user
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login?redirectTo=/dashboard");
  }

  // 2. Fetch real user profile
  const { data: profile } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  // 3. Fetch real workouts (RLS guarantees user_id = auth.uid())
  const { data: rawWorkouts } = await supabase
    .from("workouts")
    .select("*, workout_exercises(*, workout_sets(*))")
    .eq("user_id", user.id)
    .gte("started_at", rangeStart)
    .lt("started_at", rangeEnd)
    .order("started_at", { ascending: false })
    .limit(1000);

  const workouts: WorkoutRecord[] = (rawWorkouts as WorkoutRecord[]) || [];

  // 4. Fetch real hydration logs
  const { data: rawHydration } = await supabase
    .from("hydration_logs")
    .select("*")
    .eq("user_id", user.id)
    .gte("logged_at", rangeStart)
    .lt("logged_at", rangeEnd)
    .order("logged_at", { ascending: false })
    .limit(1000);

  const hydrationLogs: HydrationRecord[] = (rawHydration as HydrationRecord[]) || [];

  // 5. Fetch real nutrition logs
  const { data: rawNutrition } = await supabase
    .from("nutrition_logs")
    .select("*")
    .eq("user_id", user.id)
    .gte("logged_at", rangeStart)
    .lt("logged_at", rangeEnd)
    .order("logged_at", { ascending: false })
    .limit(1000);

  const nutritionLogs: NutritionRecord[] = (rawNutrition as NutritionRecord[]) || [];

  // Real aggregate totals (zero fabricated numbers)
  const totalWorkouts = workouts.length;
  const totalHydrationEntries = hydrationLogs.length;
  const totalHydrationMl = hydrationLogs.reduce((acc, item) => acc + (item.amount_ml || 0), 0);
  const totalNutritionEntries = nutritionLogs.length;
  const totalCaloriesLogged = nutritionLogs.reduce((acc, item) => acc + (item.calories || 0), 0);
  const totalProtein = nutritionLogs.reduce((acc, item) => acc + (item.protein_g || 0), 0);
  const totalCarbs = nutritionLogs.reduce((acc, item) => acc + (item.carbs_g || 0), 0);
  const totalFat = nutritionLogs.reduce((acc, item) => acc + (item.fat_g || 0), 0);
  const completedWorkouts = workouts.filter((workout) => workout.completed_at).length;
  const dailyActivity = new Map<string, { workouts: number; meals: number; hydration: number }>();
  for (const record of workouts) {
    const key = dateKey(record.started_at || record.created_at);
    const day = dailyActivity.get(key) || { workouts: 0, meals: 0, hydration: 0 };
    day.workouts += 1;
    dailyActivity.set(key, day);
  }
  for (const record of nutritionLogs) {
    const key = dateKey(record.logged_at || record.created_at);
    const day = dailyActivity.get(key) || { workouts: 0, meals: 0, hydration: 0 };
    day.meals += 1;
    dailyActivity.set(key, day);
  }
  for (const record of hydrationLogs) {
    const key = dateKey(record.logged_at || record.created_at);
    const day = dailyActivity.get(key) || { workouts: 0, meals: 0, hydration: 0 };
    day.hydration += record.amount_ml || 0;
    dailyActivity.set(key, day);
  }
  const activityDays = [...dailyActivity.entries()].sort(([a], [b]) => b.localeCompare(a));

  const displayName =
    profile?.display_name ||
    user.user_metadata?.full_name ||
    user.user_metadata?.name ||
    user.email?.split("@")[0] ||
    "Athlete";

  return (
    <div className="py-8 sm:py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-10">
      {/* Top Header / Profile Banner */}
      <div className="glass-panel p-6 sm:p-8 rounded-3xl border border-brand-border space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6 pb-6 border-b border-brand-border/60">
          <div className="flex items-center gap-4">
            <div className="relative h-16 w-16 rounded-2xl bg-brand-surface border border-brand-green/30 flex items-center justify-center text-brand-green overflow-hidden shadow-lg shadow-brand-green/10">
              {profile?.avatar_url || user.user_metadata?.avatar_url ? (
                <Image
                  src={profile?.avatar_url || user.user_metadata?.avatar_url}
                  alt={displayName}
                  fill
                  className="object-cover"
                />
              ) : (
                <User className="h-8 w-8" />
              )}
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h1 className="text-2xl sm:text-3xl font-black text-white">
                  {displayName}
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-brand-green/10 border border-brand-green/30 text-brand-green uppercase tracking-wider">
                  Verified Member
                </span>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-brand-blue/10 border border-brand-blue/30 text-brand-blue font-mono">
                  App v1.3.0 Client
                </span>
              </div>
              <p className="text-xs text-zinc-400 mt-0.5">{user.email}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {isAuthorizedAdminEmail(user.email) && (
              <Link
                href="/admin"
                className="inline-flex items-center gap-1.5 rounded-xl bg-brand-green/10 border border-brand-green/30 px-3.5 py-2 text-xs font-bold text-brand-green hover:bg-brand-green hover:text-black transition-all shadow-sm shadow-brand-green/10"
              >
                <ShieldCheck className="h-3.5 w-3.5" />
                Admin Hub
              </Link>
            )}
            <SignOutButton />
          </div>
        </div>

        {/* Real Summary Metrics Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-2xl bg-brand-surface/70 border border-brand-border">
            <div className="flex items-center justify-between text-zinc-400 text-xs mb-1">
              <span>Workouts Logged</span>
              <Dumbbell className="h-4 w-4 text-brand-green" />
            </div>
            <p className="text-2xl font-black text-white">{totalWorkouts}</p>
            <p className="text-[11px] text-zinc-500 mt-1">{completedWorkouts} completed sessions</p>
          </div>

          <div className="p-4 rounded-2xl bg-brand-surface/70 border border-brand-border">
            <div className="flex items-center justify-between text-zinc-400 text-xs mb-1">
              <span>Recent Hydration</span>
              <Droplets className="h-4 w-4 text-brand-blue" />
            </div>
            <p className="text-2xl font-black text-white">{totalHydrationMl} <span className="text-xs text-zinc-400 font-normal">ml</span></p>
            <p className="text-[11px] text-zinc-500 mt-1">{totalHydrationEntries} logged entries</p>
          </div>

          <div className="p-4 rounded-2xl bg-brand-surface/70 border border-brand-border">
            <div className="flex items-center justify-between text-zinc-400 text-xs mb-1">
              <span>Nutrition Entries</span>
              <Utensils className="h-4 w-4 text-amber-400" />
            </div>
            <p className="text-2xl font-black text-white">{totalCaloriesLogged} <span className="text-xs text-zinc-400 font-normal">kcal</span></p>
            <p className="text-[11px] text-zinc-500 mt-1">{totalNutritionEntries} recorded meals</p>
          </div>

          <div className="p-4 rounded-2xl bg-brand-surface/70 border border-brand-border">
            <div className="flex items-center justify-between text-zinc-400 text-xs mb-1">
              <span>Sync Status</span>
              <ShieldCheck className="h-4 w-4 text-brand-green" />
            </div>
            <p className="text-base font-bold text-brand-green mt-1">Synced & private</p>
            <p className="text-[11px] text-zinc-500 mt-1">Your account data only</p>
          </div>
        </div>
      </div>

      {/* Account-Linked Mobile App Download & Split Architecture Selector */}
      <AccountAppDownloadCard
        userEmail={user.email || ""}
        isProfileSetupCompleted={profile?.is_profile_setup_completed ?? true}
        profileVersion={profile?.version ?? 1}
      />

      <div className="glass-panel rounded-2xl border border-brand-border p-4 sm:p-5 space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <CalendarDays className="h-5 w-5 text-brand-green" />
              Progress period
            </h2>
            <p className="text-xs text-zinc-500 mt-1">
              Review your workouts, meals, and hydration for the selected period.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            {(["today", "week", "month", "all"] as const).map((option) => (
              <Link
                key={option}
                href={`/dashboard?range=${option}`}
                className={`rounded-lg px-3 py-2 text-xs font-bold capitalize transition ${
                  range === option
                    ? "bg-brand-green text-black"
                    : "bg-brand-surface text-zinc-300 border border-brand-border hover:border-brand-green/50"
                }`}
              >
                {option === "week" ? "7 days" : option}
              </Link>
            ))}
          </div>
        </div>
        <form className="flex flex-col sm:flex-row gap-2" method="get">
          <input type="hidden" name="range" value="custom" />
          <label className="text-xs text-zinc-400 flex-1">
            From
            <input name="from" type="date" defaultValue={params.from} className="mt-1 w-full rounded-lg bg-brand-surface border border-brand-border px-3 py-2 text-sm text-white" />
          </label>
          <label className="text-xs text-zinc-400 flex-1">
            To
            <input name="to" type="date" defaultValue={params.to} className="mt-1 w-full rounded-lg bg-brand-surface border border-brand-border px-3 py-2 text-sm text-white" />
          </label>
          <button type="submit" className="self-end rounded-lg bg-brand-green px-4 py-2 text-sm font-bold text-black">
            Apply range
          </button>
        </form>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="glass-panel rounded-2xl border border-brand-border p-4">
          <Activity className="h-5 w-5 text-brand-green mb-3" />
          <p className="text-2xl font-black text-white">{completedWorkouts}</p>
          <p className="text-xs text-zinc-400 mt-1">Completed workouts</p>
        </div>
        <div className="glass-panel rounded-2xl border border-brand-border p-4">
          <TrendingUp className="h-5 w-5 text-amber-400 mb-3" />
          <p className="text-2xl font-black text-white">{Math.round(totalCaloriesLogged)}</p>
          <p className="text-xs text-zinc-400 mt-1">Calories logged</p>
        </div>
        <div className="glass-panel rounded-2xl border border-brand-border p-4">
          <Utensils className="h-5 w-5 text-brand-blue mb-3" />
          <p className="text-2xl font-black text-white">{Math.round(totalProtein)}g</p>
          <p className="text-xs text-zinc-400 mt-1">Protein · {Math.round(totalCarbs)}g carbs</p>
        </div>
        <div className="glass-panel rounded-2xl border border-brand-border p-4">
          <Droplets className="h-5 w-5 text-brand-blue mb-3" />
          <p className="text-2xl font-black text-white">{Math.round(totalHydrationMl / 1000 * 10) / 10}L</p>
          <p className="text-xs text-zinc-400 mt-1">Hydration · {Math.round(totalFat)}g fat</p>
        </div>
      </div>

      {/* Main Content Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column (2 Cols): Real Workout & Nutrition Records */}
        <div className="lg:col-span-2 space-y-8">
          {/* Workouts History Section */}
          <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-brand-border">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Dumbbell className="h-5 w-5 text-brand-green" />
                Recent Workout Sessions
              </h2>
              <span className="text-xs font-mono text-zinc-500">
                {workouts.length > 0 ? `${workouts.length} Records` : "0 Records"}
              </span>
            </div>

            {workouts.length > 0 ? (
              <div className="space-y-4">
                {workouts.map((workout) => (
                  <div
                    key={workout.id}
                    className="p-4 rounded-xl bg-brand-surface border border-brand-border space-y-3"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="text-base font-bold text-white">
                          {workout.title || "Workout Session"}
                        </h3>
                        <p className="text-xs text-zinc-400 mt-0.5">
                          {new Date(workout.started_at || workout.created_at || "").toLocaleDateString(
                            undefined,
                            {
                              weekday: "short",
                              month: "short",
                              day: "numeric",
                              year: "numeric",
                            }
                          )}
                        </p>
                      </div>
                      {workout.duration_seconds && (
                        <span className="px-2.5 py-1 rounded-md text-xs font-mono bg-brand-elevated text-zinc-300 border border-brand-border">
                          {Math.floor(workout.duration_seconds / 60)}m duration
                        </span>
                      )}
                    </div>

                    {workout.notes && (
                      <p className="text-xs text-zinc-400 italic">
                        &quot;{workout.notes}&quot;
                      </p>
                    )}

                    {workout.workout_exercises && workout.workout_exercises.length > 0 && (
                      <div className="pt-2 border-t border-brand-border/60">
                        <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block mb-1.5">
                          Exercises Logged ({workout.workout_exercises.length})
                        </span>
                        <div className="flex flex-wrap gap-1.5">
                          {workout.workout_exercises.map((we, idx) => (
                            <span
                              key={we.id || idx}
                              className="px-2 py-0.5 rounded text-xs bg-brand-elevated border border-brand-border text-zinc-300"
                            >
                              Exercise #{we.order_index ?? idx + 1}
                              {we.workout_sets?.length ? ` (${we.workout_sets.length} sets)` : ""}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-12 text-center space-y-3">
                <div className="h-12 w-12 mx-auto rounded-full bg-brand-surface border border-brand-border flex items-center justify-center text-zinc-500">
                  <Dumbbell className="h-6 w-6" />
                </div>
                <h3 className="text-base font-bold text-white">No Workouts Recorded Yet</h3>
                <p className="text-xs text-zinc-400 max-w-sm mx-auto leading-relaxed">
                  Start a workout on your Fit Host Android or iOS application. When you save your sets, they will appear here automatically via cloud synchronization.
                </p>
              </div>
            )}
          </div>

          {/* Nutrition History Section */}
          <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-brand-border space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-brand-border">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Utensils className="h-5 w-5 text-amber-400" />
                Macro & Nutrition History
              </h2>
              <span className="text-xs font-mono text-zinc-500">
                {nutritionLogs.length > 0 ? `${nutritionLogs.length} Entries` : "0 Entries"}
              </span>
            </div>

            {nutritionLogs.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {nutritionLogs.map((log) => (
                  <div
                    key={log.id}
                    className="p-4 rounded-xl bg-brand-surface border border-brand-border space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white uppercase tracking-wider">
                        {log.meal_type || "Meal"}
                      </span>
                      <span className="text-xs font-mono text-amber-400 font-bold">
                        {log.calories || 0} kcal
                      </span>
                    </div>
                    <div className="grid grid-cols-3 gap-1 pt-1 text-[11px] text-zinc-400 border-t border-brand-border/60">
                      <div>P: {log.protein_g || 0}g</div>
                      <div>C: {log.carbs_g || 0}g</div>
                      <div>F: {log.fat_g || 0}g</div>
                    </div>
                    <p className="text-[10px] text-zinc-500">
                      {new Date(log.logged_at || log.created_at || "").toLocaleDateString()}
                    </p>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-8 text-center space-y-2">
                <div className="h-10 w-10 mx-auto rounded-full bg-brand-surface border border-brand-border flex items-center justify-center text-zinc-500">
                  <Utensils className="h-5 w-5" />
                </div>
                <h3 className="text-sm font-bold text-white">No Nutrition Logs Found</h3>
                <p className="text-xs text-zinc-400 max-w-xs mx-auto">
                  Log your daily macros or meal breakdown in the mobile app to sync records.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Right Column (1 Col): Hydration & Cloud Sync Account Info */}
        <div className="space-y-8">
          {/* Hydration Panel */}
          <div className="glass-panel p-6 rounded-2xl border border-brand-border space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Droplets className="h-5 w-5 text-brand-blue" />
              Hydration Stream
            </h2>

            {hydrationLogs.length > 0 ? (
              <div className="space-y-2">
                {hydrationLogs.map((log) => (
                  <div
                    key={log.id}
                    className="p-3 rounded-lg bg-brand-surface border border-brand-border flex items-center justify-between text-xs"
                  >
                    <div className="flex items-center gap-2">
                      <div className="h-2 w-2 rounded-full bg-brand-blue" />
                      <span className="text-white font-semibold">{log.amount_ml} ml</span>
                    </div>
                    <span className="text-zinc-500 text-[11px]">
                      {new Date(log.logged_at || log.created_at || "").toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-6 text-center text-xs text-zinc-400">
                No hydration entries logged yet today.
              </div>
            )}
          </div>

          {/* Daily activity breakdown */}
          <div className="glass-panel p-6 rounded-2xl border border-brand-border space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <CalendarDays className="h-5 w-5 text-brand-green" />
              Daily activity
            </h2>
            {activityDays.length > 0 ? (
              <div className="space-y-2">
                {activityDays.slice(0, 14).map(([day, summary]) => (
                  <div key={day} className="rounded-xl bg-brand-surface border border-brand-border p-3">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-semibold text-white">{formatDay(day)}</span>
                      <span className="text-[11px] text-zinc-500">{summary.meals} meals</span>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-[11px] text-zinc-400">
                      <span>{summary.workouts} workouts</span>
                      <span>{summary.hydration} ml water</span>
                      <span>{summary.meals} nutrition logs</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-zinc-400">No activity in this period.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
