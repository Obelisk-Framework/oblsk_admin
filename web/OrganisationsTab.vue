<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import Obelisk from '@/obelisk.js'

const orgs = ref([])
const selectedId = ref(null)
const draft = ref(null)
const newDept = ref('')
const newRankName = ref('')
const newRankGrade = ref(0)
const newContact = ref({ number: '', label: '' })

const selected = computed(() => orgs.value.find(o => o.id === selectedId.value) || orgs.value[0] || null)

const onReply = ({ orgs: nextOrgs }) => {
  orgs.value = nextOrgs
  if (!selectedId.value && nextOrgs.length) selectedId.value = nextOrgs[0].id
}

onMounted(() => {
  Obelisk.on('admin:client:organisations-reply', onReply)
  Obelisk.emit('admin:client:organisations-list', {})
})
onBeforeUnmount(() => Obelisk.off('admin:client:organisations-reply', onReply))

const createOrg = () => {
  draft.value = { name: '', shortCode: '', colour: '#3b82f6', type: 'Government' }
}
const submitCreate = () => {
  Obelisk.emit('admin:client:organisations-create', draft.value)
  draft.value = null
}

const setDetails = (org) => {
  Obelisk.emit('admin:client:organisations-setDetails', {
    orgId: org.id, shortCode: org.short_code, colour: org.colour, type: org.type,
  })
}

const addDepartment = (org) => {
  if (!newDept.value.trim()) return
  Obelisk.emit('admin:client:organisations-addDepartment', { orgId: org.id, name: newDept.value.trim() })
  newDept.value = ''
}
const removeDepartment = (deptId) => Obelisk.emit('admin:client:organisations-removeDepartment', { deptId })

const addRank = (org) => {
  if (!newRankName.value.trim()) return
  Obelisk.emit('admin:client:organisations-addRank', { orgId: org.id, name: newRankName.value.trim(), grade: Number(newRankGrade.value) || 0 })
  newRankName.value = ''
  newRankGrade.value = 0
}
const removeRank = (rankId) => Obelisk.emit('admin:client:organisations-removeRank', { rankId })

const addContactNumber = (org) => {
  if (!newContact.value.number.trim()) return
  Obelisk.emit('admin:client:organisations-addContactNumber', { orgId: org.id, number: newContact.value.number.trim(), label: newContact.value.label.trim() || 'Main line' })
  newContact.value = { number: '', label: '' }
}
const removeContactNumber = (contactId) => Obelisk.emit('admin:client:organisations-removeContactNumber', { contactId })
const toggleContactNumber = (contact) => Obelisk.emit('admin:client:organisations-toggleContactNumber', { contactId: contact.id, enabled: !contact.enabled })

const COLOURS = ['#3b82f6', '#10b981', '#e0b64a', '#f59e0b', '#ef4444', '#a78bfa']
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 300px 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Organisations · {{ orgs.length }}</span>
        <button @click="createOrg" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
      </div>
      <div class="overflow-y-auto" style="max-height: 520px">
        <button v-for="o in orgs" :key="o.id" @click="selectedId = o.id; draft = null"
          class="w-full px-3.5 py-2.5 flex items-center gap-2.5 border-b border-white/6 text-left transition"
          :class="selectedId === o.id && !draft ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
          <span class="w-2 h-8 rounded-full shrink-0" :style="{ background: o.colour || '#6b7280' }" />
          <span class="min-w-0 flex-1">
            <span class="block text-[12px] truncate">{{ o.name }}</span>
            <span class="block ob-mono text-[9px] text-white/35">{{ o.short_code || '—' }} · {{ o.departments.length }} DEPTS · {{ o.ranks.length }} RANKS</span>
          </span>
        </button>
        <div v-if="!orgs.length" class="py-6 text-center text-[11.5px] text-white/30">No organisations yet.</div>
      </div>
    </div>

    <div v-if="draft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div class="text-[13px] font-medium">New organisation</div>
      <input v-model="draft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-model="draft.shortCode" placeholder="Short code" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-1.5">
        <button v-for="c in COLOURS" :key="c" @click="draft.colour = c" class="w-7 h-7 rounded-md"
          :style="{ background: c, outline: draft.colour === c ? '2px solid #fff' : '1px solid rgba(255,255,255,.12)' }" />
      </div>
      <div class="flex gap-1.5">
        <button v-for="t in ['Government', 'Business']" :key="t" @click="draft.type = t"
          class="h-8 px-2.5 rounded-lg text-[11.5px] transition"
          :class="draft.type === t ? 'text-black font-medium' : 'bg-white/[0.05] text-white/50'"
          :style="draft.type === t ? { background: 'var(--ob-accent)' } : undefined">{{ t }}</button>
      </div>
      <div class="flex gap-2 pt-1">
        <button @click="draft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create organisation</button>
      </div>
    </div>

    <div v-else-if="selected" class="grid gap-3" style="grid-template-columns: 1fr 1fr">
      <div class="rounded-xl border border-white/10 bg-white/[0.03] p-4 col-span-2 grid gap-3" style="grid-template-columns: 1fr 140px 200px">
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Name</div>
          <input v-model="selected.name" @change="setDetails(selected)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Short code</div>
          <input v-model="selected.short_code" @change="setDetails(selected)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
        </div>
        <div>
          <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Colour / type</div>
          <div class="flex gap-1.5 flex-wrap items-center">
            <button v-for="c in COLOURS" :key="c" @click="selected.colour = c; setDetails(selected)" class="w-7 h-7 rounded-md"
              :style="{ background: c, outline: selected.colour === c ? '2px solid #fff' : '1px solid rgba(255,255,255,.12)' }" />
            <button v-for="t in ['Government', 'Business']" :key="t" @click="selected.type = t; setDetails(selected)"
              class="h-7 px-2 rounded text-[10.5px]"
              :class="selected.type === t ? 'text-black font-medium' : 'bg-white/[0.05] text-white/50'"
              :style="selected.type === t ? { background: 'var(--ob-accent)' } : undefined">{{ t }}</button>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden">
        <div class="px-4 py-2.5 border-b border-white/8 text-[12.5px] font-medium">Departments · {{ selected.departments.length }}</div>
        <div class="p-3 space-y-1.5 overflow-y-auto" style="max-height: 220px">
          <div v-for="d in selected.departments" :key="d.id" class="flex items-center gap-2 rounded-lg border border-white/10 bg-black/30 px-2.5 h-9">
            <span class="text-[11.5px] flex-1 truncate">{{ d.name }}</span>
            <button @click="removeDepartment(d.id)" class="w-6 h-6 rounded text-white/30 hover:text-red-300">×</button>
          </div>
          <div v-if="!selected.departments.length" class="py-4 text-center text-[11.5px] text-white/30">No departments yet.</div>
        </div>
        <div class="p-3 border-t border-white/8 flex gap-2">
          <input v-model="newDept" placeholder="Add a department" class="flex-1 h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
          <button @click="addDepartment(selected)" class="h-9 px-3.5 rounded-lg text-black text-[12px] font-medium shrink-0" style="background: var(--ob-accent)">Add</button>
        </div>
      </div>

      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden">
        <div class="px-4 py-2.5 border-b border-white/8 text-[12.5px] font-medium">Ranks · {{ selected.ranks.length }}</div>
        <div class="p-3 space-y-1.5 overflow-y-auto" style="max-height: 220px">
          <div v-for="r in selected.ranks" :key="r.id" class="flex items-center gap-2 rounded-lg border border-white/10 bg-black/30 px-2.5 h-9">
            <span class="ob-mono text-[9px] text-white/30 w-6 shrink-0">{{ r.grade }}</span>
            <span class="text-[11.5px] flex-1 truncate">{{ r.name }}</span>
            <button @click="removeRank(r.id)" class="w-6 h-6 rounded text-white/30 hover:text-red-300">×</button>
          </div>
          <div v-if="!selected.ranks.length" class="py-4 text-center text-[11.5px] text-white/30">No ranks yet.</div>
        </div>
        <div class="p-3 border-t border-white/8 flex gap-2">
          <input v-model="newRankName" placeholder="Rank name" class="flex-1 h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
          <input v-model.number="newRankGrade" type="number" placeholder="Grade" class="w-20 h-9 px-2 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          <button @click="addRank(selected)" class="h-9 px-3.5 rounded-lg text-black text-[12px] font-medium shrink-0" style="background: var(--ob-accent)">Add</button>
        </div>
      </div>

      <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden col-span-2">
        <div class="px-4 py-2.5 border-b border-white/8 text-[12.5px] font-medium">Contact numbers · {{ selected.contact_numbers.length }}</div>
        <div class="p-3 flex flex-wrap gap-2">
          <div v-for="c in selected.contact_numbers" :key="c.id" class="flex items-center gap-2 rounded-lg border border-white/10 bg-black/30 px-2.5 h-9">
            <button @click="toggleContactNumber(c)" class="ob-mono text-[10px]" :style="{ color: c.enabled ? 'var(--ob-accent)' : 'rgba(255,255,255,.3)' }">{{ c.enabled ? 'ON' : 'OFF' }}</button>
            <span class="ob-mono text-[11px]">{{ c.number }}</span>
            <span class="text-[10.5px] text-white/40">{{ c.label }}</span>
            <button @click="removeContactNumber(c.id)" class="w-5 h-5 rounded text-white/30 hover:text-red-300">×</button>
          </div>
        </div>
        <div class="p-3 border-t border-white/8 flex gap-2">
          <input v-model="newContact.number" placeholder="Number" class="w-32 h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
          <input v-model="newContact.label" placeholder="Label" class="flex-1 h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
          <button @click="addContactNumber(selected)" class="h-9 px-3.5 rounded-lg text-black text-[12px] font-medium shrink-0" style="background: var(--ob-accent)">Add</button>
        </div>
      </div>
    </div>

    <div v-else class="grid place-items-center text-white/30 text-[12px]">No organisation selected.</div>
  </div>
</template>
