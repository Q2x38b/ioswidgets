import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

// Get all tasks for a user
export const list = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
  },
});

// Get tasks for a specific date
export const listByDate = query({
  args: { userId: v.string(), dueDate: v.number() },
  handler: async (ctx, args) => {
    // Get start and end of the day
    const startOfDay = new Date(args.dueDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(args.dueDate);
    endOfDay.setHours(23, 59, 59, 999);

    const tasks = await ctx.db
      .query("tasks")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    return tasks.filter((task) => {
      if (!task.dueDate) return false;
      return task.dueDate >= startOfDay.getTime() && task.dueDate <= endOfDay.getTime();
    });
  },
});

// Get completed tasks for a user
export const listCompleted = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .withIndex("by_user_and_completed", (q) =>
        q.eq("userId", args.userId).eq("isCompleted", true)
      )
      .collect();
  },
});

// Create a new task
export const create = mutation({
  args: {
    userId: v.string(),
    title: v.string(),
    description: v.optional(v.string()),
    dueDate: v.optional(v.number()),
    startTime: v.optional(v.string()),
    endTime: v.optional(v.string()),
    color: v.optional(v.string()),
    priority: v.optional(v.string()),
    status: v.optional(v.string()),
    customTags: v.optional(v.array(v.string())),
    subtasks: v.optional(v.array(v.string())),
    order: v.optional(v.number()),
    recurring: v.optional(v.string()),
    reminder: v.optional(v.string()),
    duration: v.optional(v.number()),
    location: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const taskId = await ctx.db.insert("tasks", {
      userId: args.userId,
      title: args.title,
      description: args.description ?? "",
      isCompleted: false,
      createdAt: Date.now(),
      completedAt: undefined,
      dueDate: args.dueDate,
      startTime: args.startTime,
      endTime: args.endTime,
      color: args.color ?? "grey",
      priority: args.priority ?? "none",
      status: args.status ?? "",
      customTags: args.customTags ?? [],
      subtasks: args.subtasks ?? [],
      order: args.order ?? 0,
      recurring: args.recurring ?? "",
      reminder: args.reminder,
      duration: args.duration ?? 0,
      location: args.location ?? "",
    });
    return taskId;
  },
});

// Update a task
export const update = mutation({
  args: {
    id: v.id("tasks"),
    title: v.optional(v.string()),
    description: v.optional(v.string()),
    isCompleted: v.optional(v.boolean()),
    dueDate: v.optional(v.union(v.number(), v.null())),
    startTime: v.optional(v.union(v.string(), v.null())),
    endTime: v.optional(v.union(v.string(), v.null())),
    color: v.optional(v.string()),
    priority: v.optional(v.string()),
    status: v.optional(v.string()),
    customTags: v.optional(v.array(v.string())),
    subtasks: v.optional(v.array(v.string())),
    order: v.optional(v.number()),
    recurring: v.optional(v.string()),
    reminder: v.optional(v.union(v.string(), v.null())),
    duration: v.optional(v.number()),
    location: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;

    // Handle completedAt based on isCompleted
    const existingTask = await ctx.db.get(id);
    if (!existingTask) {
      throw new Error("Task not found");
    }

    const finalUpdates: Record<string, unknown> = {};

    // Only include non-undefined values
    for (const [key, value] of Object.entries(updates)) {
      if (value !== undefined) {
        finalUpdates[key] = value;
      }
    }

    // Handle completion timestamp
    if (updates.isCompleted !== undefined) {
      if (updates.isCompleted && !existingTask.isCompleted) {
        finalUpdates.completedAt = Date.now();
      } else if (!updates.isCompleted && existingTask.isCompleted) {
        finalUpdates.completedAt = undefined;
      }
    }

    await ctx.db.patch(id, finalUpdates);
    return id;
  },
});

// Toggle task completion
export const toggle = mutation({
  args: { id: v.id("tasks") },
  handler: async (ctx, args) => {
    const task = await ctx.db.get(args.id);
    if (!task) {
      throw new Error("Task not found");
    }

    const isCompleted = !task.isCompleted;
    await ctx.db.patch(args.id, {
      isCompleted,
      completedAt: isCompleted ? Date.now() : undefined,
    });
    return args.id;
  },
});

// Delete a task
export const remove = mutation({
  args: { id: v.id("tasks") },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.id);
  },
});

// Delete all completed tasks for a user
export const removeCompleted = mutation({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    const completedTasks = await ctx.db
      .query("tasks")
      .withIndex("by_user_and_completed", (q) =>
        q.eq("userId", args.userId).eq("isCompleted", true)
      )
      .collect();

    for (const task of completedTasks) {
      await ctx.db.delete(task._id);
    }

    return completedTasks.length;
  },
});
