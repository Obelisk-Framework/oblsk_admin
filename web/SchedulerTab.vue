<!-- plugins/oblsk_admin/web/SchedulerTab.vue -->
<script setup>
import { ref, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const jobs = ref([])
const actions = ref([])
const createDraft = ref(null)

const DEV_JOBS = [
  { id: 1, action_id: 'refill_shops', schedule_type: 'interval', interval_seconds: 3600, cron_expression: null, enabled: 1, last_run_at: null },
  { id: 2, action_id: 'cleanup_bins', schedule_type: 'cron', interval_seconds: null, cron_expression: '0 4 * * *', enabled: 1, last_run_at: null },
]
const DEV_ACTIONS = [
  { action_id: 'refill_shops', label: 'Refill Shops' },
  { action_id: 'cleanup_bins', label: 'Cleanup Bins' },
]

const fetchList = () => {
  if (import.meta.env.DEV) { jobs.value = DEV_JOBS; actions.value = DEV_ACTIONS; return }
  Obelisk.emit('admin:client:scheduler-list', {})
}

const onReply = ({ jobs: next, actions: nextActions }) => { jobs.value = next; actions.value = nextActions }

onMounted(() => {
  Obelisk.on('admin:client:scheduler-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:scheduler-reply', onReply))

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

const openCreate = () => { createDraft.value = { actionId: '', scheduleType: 'interval', intervalSeconds: 3600, cronExpression: '' } }
const submitCreate = () => {
  Obelisk.emit('admin:client:scheduler-create', {
    actionId: createDraft.value.actionId,
    scheduleType: createDraft.value.scheduleType,
    intervalSeconds: createDraft.value.scheduleType === 'interval' ? Number(createDraft.value.intervalSeconds) : null,
    cronExpression: createDraft.value.scheduleType === 'cron' ? createDraft.value.cronExpression : null,
  })
  createDraft.value = null
}

const toggleEnabled = (job) => {
  Obelisk.emit('admin:client:scheduler-update', { id: job.id, attributes: { enabled: job.enabled ? 0 : 1 } })
}
const deleteJob = (job) => Obelisk.emit('admin:client:scheduler-delete', { id: job.id })
</script>

<template>
  <div class="flex flex-col gap-3 min-h-0 p-5">
    <div class="flex items-center justify-between">
      <span class="text-[12.5px] font-medium">Scheduled Jobs · {{ jobs.length }}</span>
      <button class="text-[11px] text-white/60 hover:text-white" @click="openCreate">+ New</button>
    </div>

    <div v-if="createDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 flex flex-col gap-2">
      <select v-model="createDraft.actionId" class="bg-white/5 rounded px-2 py-1 text-[12px]">
        <option value="" disabled>Select an action</option>
        <option v-for="a in actions" :key="a.action_id" :value="a.action_id">{{ a.label }} ({{ a.action_id }})</option>
      </select>
      <select v-model="createDraft.scheduleType" class="bg-white/5 rounded px-2 py-1 text-[12px]">
        <option value="interval">Interval</option>
        <option value="cron">Cron</option>
      </select>
      <input v-if="createDraft.scheduleType === 'interval'" v-model.number="createDraft.intervalSeconds" type="number" placeholder="Interval (seconds)" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <input v-else v-model="createDraft.cronExpression" placeholder="Cron expression (min hour day month weekday)" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <div class="flex gap-2">
        <button class="text-[11px] px-2 py-1 rounded" style="background: var(--ob-accent)" @click="submitCreate">Create</button>
        <button class="text-[11px] px-2 py-1 rounded bg-white/10" @click="createDraft = null">Cancel</button>
      </div>
    </div>

    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-y-auto flex-1">
      <div v-for="job in jobs" :key="job.id" class="flex items-center justify-between px-4 py-2.5 border-b border-white/5 text-[12px]">
        <div>
          <div class="font-medium">{{ job.action_id }}</div>
          <div class="text-white/45">
            {{ job.schedule_type === 'interval' ? `every ${job.interval_seconds}s` : job.cron_expression }}
            — last run: {{ job.last_run_at ? new Date(job.last_run_at * 1000).toLocaleString() : 'never' }}
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button class="text-[11px] px-2 py-1 rounded" :class="job.enabled ? 'bg-white/10' : ''" @click="toggleEnabled(job)">{{ job.enabled ? 'Enabled' : 'Disabled' }}</button>
          <button class="text-white/40 hover:text-red-300" @click="deleteJob(job)">×</button>
        </div>
      </div>
    </div>
  </div>
</template>
