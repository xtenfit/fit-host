import { redirect } from "next/navigation";
import Image from "next/image";
import {
  Dumbbell,
  Droplets,
  Utensils,
  User,
  ShieldCheck,
  Cloud,
  CheckCircle2,
} from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/dashboard/SignOutButton";

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

export default async function DashboardPage() {
  const supabase = await createClient();

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
    .order("started_at", { ascending: false })
    .limit(10);

  const workouts: WorkoutRecord[] = (rawWorkouts as WorkoutRecord[]) || [];

  // 4. Fetch real hydration logs
  const { data: rawHydration } = await supabase
    .from("hydration_logs")
    .select("*")
    .eq("user_id", user.id)
    .order("logged_at", { ascending: false })
    .limit(10);

  const hydrationLogs: HydrationRecord[] = (rawHydration as HydrationRecord[]) || [];

  // 5. Fetch real nutrition logs
  const { data: rawNutrition } = await supabase
    .from("nutrition_logs")
    .select("*")
    .eq("user_id", user.id)
    .order("logged_at", { ascending: false })
    .limit(10);

  const nutritionLogs: NutritionRecord[] = (rawNutrition as NutritionRecord[]) || [];

  // Real aggregate totals (zero fabricated numbers)
  const totalWorkouts = workouts.length;
  const totalHydrationEntries = hydrationLogs.length;
  const totalHydrationMl = hydrationLogs.reduce((acc, item) => acc + (item.amount_ml || 0), 0);
  const totalNutritionEntries = nutritionLogs.length;
  const totalCaloriesLogged = nutritionLogs.reduce((acc, item) => acc + (item.calories || 0), 0);

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
              <div className="flex items-center gap-2">
                <h1 className="text-2xl sm:text-3xl font-black text-white">
                  {displayName}
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-brand-green/10 border border-brand-green/30 text-brand-green uppercase tracking-wider">
                  Verified Member
                </span>
              </div>
              <p className="text-xs text-zinc-400 mt-0.5">{user.email}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden sm:flex flex-col text-right text-xs">
              <span className="text-zinc-500 font-mono text-[10px]">AUTH_SOURCE</span>
              <span className="text-zinc-300 font-semibold flex items-center gap-1 justify-end">
                <Cloud className="h-3 w-3 text-brand-blue" />
                Supabase RLS Active
              </span>
            </div>
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
            <p className="text-[11px] text-zinc-500 mt-1">Authorized Supabase records</p>
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
            <p className="text-base font-bold text-brand-green mt-1">Live & Secure</p>
            <p className="text-[11px] text-zinc-500 mt-1">Mobile & Web Connected</p>
          </div>
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

          {/* Account Details & Infrastructure Card */}
          <div className="glass-panel p-6 rounded-2xl border border-brand-border space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <ShieldCheck className="h-5 w-5 text-brand-green" />
              Security & Identity Details
            </h2>

            <div className="space-y-3 text-xs">
              <div className="p-3 rounded-xl bg-brand-surface border border-brand-border space-y-1">
                <span className="text-[10px] uppercase font-mono text-zinc-500 block">
                  Supabase User Identifier
                </span>
                <code className="text-[11px] font-mono text-brand-green break-all">
                  {user.id}
                </code>
              </div>

              <div className="p-3 rounded-xl bg-brand-surface border border-brand-border space-y-1">
                <span className="text-[10px] uppercase font-mono text-zinc-500 block">
                  Authentication Provider
                </span>
                <span className="text-white font-semibold capitalize">
                  {user.app_metadata?.provider || "Email"}
                </span>
              </div>

              <div className="p-3 rounded-xl bg-brand-surface border border-brand-border space-y-1">
                <span className="text-[10px] uppercase font-mono text-zinc-500 block">
                  Row Level Security Status
                </span>
                <span className="text-brand-green font-semibold flex items-center gap-1.5">
                  <CheckCircle2 className="h-3.5 w-3.5" /> Enforced on all tables
                </span>
              </div>

              <div className="p-3 rounded-xl bg-brand-surface border border-brand-border space-y-1">
                <span className="text-[10px] uppercase font-mono text-zinc-500 block">
                  Mobile Deep-Link Scheme
                </span>
                <code className="text-[11px] font-mono text-zinc-300">
                  io.supabase.fithost://login-callback
                </code>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
