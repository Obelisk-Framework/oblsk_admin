<!-- plugins/oblsk_admin/web/JobsTab.vue -->
<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const jobs = ref([])
const selectedId = ref(null)
const detail = ref({ levels: [], tasks: [], routes: [] })
const createDraft = ref(null)

const selected = computed(() => jobs.value.find(j => j.id === selectedId.value) || null)

const DEV_JOBS = [
  { id: 1, key: 'busdriver', name: 'Bus Driver', icon: 'bus', description: 'Drive scheduled routes.', active: 1 },
  { id: 2, key: 'gardener', name: 'Gardener', icon: 'leaf', description: 'Tend to public greenery.', active: 1 },
]
const DEV_DETAIL = {
  levels: [{ id: 1, level: 1, xp_required: 0, label: 'Rookie' }, { id: 2, level: 2, xp_required: 500, label: 'Veteran' }],
  tasks: [{ id: 1, task_key: 'drop_off_passenger', pay_amount: 50, xp_amount: 10 }],
  routes: [{ id: 1, name: 'Downtown Loop', min_level: 1, stops: [] }],
}

const fetchList = () => {
  if (import.meta.env.DEV) { jobs.value = DEV_JOBS; return }
  Obelisk.emit('admin:client:jobs-list', {})
}

const fetchDetail = (jobId) => {
  if (import.meta.env.DEV) { detail.value = DEV_DETAIL; return }
  Obelisk.emit('admin:client:jobs-detail', { jobId })
}

const selectJob = (job) => {
  selectedId.value = job.id
  fetchDetail(job.id)
}

const onListReply = ({ jobs: next }) => { jobs.value = next }
const onDetailReply = ({ levels, tasks, routes }) => { detail.value = { levels, tasks, routes } }

onMounted(() => {
  Obelisk.on('admin:client:jobs-reply', onListReply)
  Obelisk.on('admin:client:jobs-detail-reply', onDetailReply)
  fetchList()
})
onBeforeUnmount(() => {
  Obelisk.off('admin:client:jobs-reply', onListReply)
  Obelisk.off('admin:client:jobs-detail-reply', onDetailReply)
})

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

const openCreate = () => { createDraft.value = { key: '', name: '', icon: '', description: '' } }
const submitCreate = () => {
  Obelisk.emit('admin:client:jobs-create', { attributes: createDraft.value })
  createDraft.value = null
}
const deleteJob = (job) => {
  Obelisk.emit('admin:client:jobs-delete', { jobId: job.id })
  if (selectedId.value === job.id) selectedId.value = null
}

const levelDraft = ref(null)
const openAddLevel = () => { levelDraft.value = { level: (detail.value.levels.length + 1), xpRequired: 0, label: '' } }
const submitLevel = () => {
  Obelisk.emit('admin:client:jobs-upsert-level', { jobId: selectedId.value, ...levelDraft.value })
  levelDraft.value = null
}
const deleteLevel = (level) => Obelisk.emit('admin:client:jobs-delete-level', { jobId: selectedId.value, levelId: level.id })

const taskDraft = ref(null)
const openAddTask = () => { taskDraft.value = { taskKey: '', payAmount: 0, xpAmount: 0 } }
const submitTask = () => {
  Obelisk.emit('admin:client:jobs-upsert-task', { jobId: selectedId.value, ...taskDraft.value })
  taskDraft.value = null
}
const deleteTask = (task) => Obelisk.emit('admin:client:jobs-delete-task', { jobId: selectedId.value, taskId: task.id })

const routeDraft = ref(null)
const openAddRoute = () => { routeDraft.value = { name: '', minLevel: 1, stops: [] } }
const submitRoute = () => {
  Obelisk.emit('admin:client:jobs-upsert-route', { jobId: selectedId.value, ...routeDraft.value })
  routeDraft.value = null
}
const deleteRoute = (route) => Obelisk.emit('admin:client:jobs-delete-route', { jobId: selectedId.value, routeId: route.id })
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 300px 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Jobs · {{ jobs.length }}</span>
        <button class="text-[11px] text-white/60 hover:text-white" @click="openCreate">+ New</button>
      </div>
      <div class="overflow-y-auto flex-1">
        <button v-for="job in jobs" :key="job.id" @click="selectJob(job)"
          class="w-full text-left px-4 py-2.5 border-b border-white/5 hover:bg-white/5"
          :class="selectedId === job.id ? 'bg-white/8' : ''">
          <div class="text-[13px] font-medium">{{ job.name }}</div>
          <div class="text-[11px] text-white/45">{{ job.key }}</div>
        </button>
      </div>
    </div>

    <div v-if="createDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 flex flex-col gap-2">
      <input v-model="createDraft.key" placeholder="key (e.g. busdriver)" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <input v-model="createDraft.name" placeholder="Name" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <input v-model="createDraft.icon" placeholder="Icon" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <input v-model="createDraft.description" placeholder="Description" class="bg-white/5 rounded px-2 py-1 text-[12px]" />
      <div class="flex gap-2">
        <button class="text-[11px] px-2 py-1 rounded" style="background: var(--ob-accent)" @click="submitCreate">Create</button>
        <button class="text-[11px] px-2 py-1 rounded bg-white/10" @click="createDraft = null">Cancel</button>
      </div>
    </div>

    <div v-else-if="selected" class="rounded-xl border border-white/10 bg-white/[0.03] overflow-y-auto flex flex-col gap-4 p-4">
      <div class="flex items-center justify-between">
        <div class="text-[14px] font-medium">{{ selected.name }}</div>
        <button class="text-[11px] text-red-400 hover:text-red-300" @click="deleteJob(selected)">Delete job</button>
      </div>

      <div>
        <div class="flex items-center justify-between mb-1">
          <span class="text-[12px] font-medium text-white/70">Levels</span>
          <button class="text-[11px] text-white/60 hover:text-white" @click="openAddLevel">+ Add</button>
        </div>
        <div v-for="lvl in detail.levels" :key="lvl.id" class="flex items-center justify-between text-[12px] py-1 border-b border-white/5">
          <span>Lvl {{ lvl.level }} — {{ lvl.label }} ({{ lvl.xp_required }} xp)</span>
          <button class="text-white/40 hover:text-red-300" @click="deleteLevel(lvl)">×</button>
        </div>
        <div v-if="levelDraft" class="flex gap-2 mt-2">
          <input v-model.number="levelDraft.level" type="number" class="w-14 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <input v-model.number="levelDraft.xpRequired" type="number" placeholder="xp" class="w-20 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <input v-model="levelDraft.label" placeholder="label" class="flex-1 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <button class="text-[11px] px-2 rounded" style="background: var(--ob-accent)" @click="submitLevel">Save</button>
        </div>
      </div>

      <div>
        <div class="flex items-center justify-between mb-1">
          <span class="text-[12px] font-medium text-white/70">Tasks</span>
          <button class="text-[11px] text-white/60 hover:text-white" @click="openAddTask">+ Add</button>
        </div>
        <div v-for="t in detail.tasks" :key="t.id" class="flex items-center justify-between text-[12px] py-1 border-b border-white/5">
          <span>{{ t.task_key }} — ${{ t.pay_amount }} / {{ t.xp_amount }} xp</span>
          <button class="text-white/40 hover:text-red-300" @click="deleteTask(t)">×</button>
        </div>
        <div v-if="taskDraft" class="flex gap-2 mt-2">
          <input v-model="taskDraft.taskKey" placeholder="task_key" class="flex-1 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <input v-model.number="taskDraft.payAmount" type="number" placeholder="pay" class="w-16 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <input v-model.number="taskDraft.xpAmount" type="number" placeholder="xp" class="w-16 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <button class="text-[11px] px-2 rounded" style="background: var(--ob-accent)" @click="submitTask">Save</button>
        </div>
      </div>

      <div>
        <div class="flex items-center justify-between mb-1">
          <span class="text-[12px] font-medium text-white/70">Bus routes</span>
          <button class="text-[11px] text-white/60 hover:text-white" @click="openAddRoute">+ Add</button>
        </div>
        <div v-for="r in detail.routes" :key="r.id" class="flex items-center justify-between text-[12px] py-1 border-b border-white/5">
          <span>{{ r.name }} — min lvl {{ r.min_level }} ({{ (r.stops || []).length }} stops)</span>
          <button class="text-white/40 hover:text-red-300" @click="deleteRoute(r)">×</button>
        </div>
        <div v-if="routeDraft" class="flex gap-2 mt-2">
          <input v-model="routeDraft.name" placeholder="Route name" class="flex-1 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <input v-model.number="routeDraft.minLevel" type="number" placeholder="min lvl" class="w-20 bg-white/5 rounded px-2 py-1 text-[12px]" />
          <button class="text-[11px] px-2 rounded" style="background: var(--ob-accent)" @click="submitRoute">Save</button>
        </div>
      </div>
    </div>

    <div v-else class="rounded-xl border border-white/10 bg-white/[0.03] flex items-center justify-center text-white/40 text-[12px]">
      Select a job
    </div>
  </div>
</template>
