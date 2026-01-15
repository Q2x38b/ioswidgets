import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  tasks: defineTable({
    userId: v.string(),
    title: v.string(),
    description: v.string(),
    isCompleted: v.boolean(),
    createdAt: v.number(),
    completedAt: v.optional(v.number()),
    dueDate: v.optional(v.number()),
    startTime: v.optional(v.string()),
    endTime: v.optional(v.string()),
    color: v.string(),
    priority: v.string(),
    status: v.string(),
    customTags: v.array(v.string()),
    subtasks: v.array(v.string()),
    order: v.number(),
    recurring: v.string(),
    reminder: v.optional(v.string()),
    duration: v.number(),
    location: v.string(),
  })
    .index("by_user", ["userId"])
    .index("by_user_and_date", ["userId", "dueDate"])
    .index("by_user_and_completed", ["userId", "isCompleted"]),
});
