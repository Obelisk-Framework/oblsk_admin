<script setup>
import { ref, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const bans = ref([])
const logs = ref([])
const draft = ref(null) // { kind: 'ban'|'warn'|'kick', accountId, reason, durationHours }

const DEV_BANS = [
  { id: 1, account_id: 7, display_name: 'Ricky Stone', reason: 'RDM', issued_by: '1', expires_at: null, revoked_at: null, created_at: '2026-08-14 10:00:00' },
]
const DEV_LOGS = [
  { id: 1, account_id: 8, display_name: 'Mila Fenn', type: 'warn', reason: 'Chat spam', issued_by: '1', created_at: '2026-08-15 09:00:00' },
]

const onReply = (payload) => { bans.value = payload.bans; logs.value = payload.logs }

const fetchLists = () => {
  if (import.meta.env.DEV) { bans.value = DEV_BANS; logs.value = DEV_LOGS; return }
  Obelisk.emit('admin:client:moderation-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:moderation-reply', onReply)
  fetchLists()
})
onBeforeUnmount(() => Obelisk.off('admin:client:moderation-reply', onReply))

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchLists() })
}

const openDraft = (kind) => { draft.value = { kind, accountId: '', reason: '', durationHours: '' } }
const submitDraft = () => {
  const accountId = Number(draft.value.accountId)
  const reason = draft.value.reason || 'No reason given'
  if (draft.value.kind === 'ban') {
    Obelisk.emit('admin:client:moderation-ban', { accountId, reason, durationHours: draft.value.durationHours ? Number(draft.value.durationHours) : null })
  } else if (draft.value.kind === 'warn') {
    Obelisk.emit('admin:client:moderation-warn', { accountId, reason })
  } else if (draft.value.kind === 'kick') {
    Obelisk.emit('admin:client:moderation-kick', { accountId, reason })
  }
  draft.value = null
}
const unban = (banId) => Obelisk.emit('admin:client:moderation-unban', { banId })
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 1fr 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Bans · {{ bans.length }}</span>
        <button @click="openDraft('ban')" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ BAN</button>
      </div>
      <div class="overflow-y-auto" style="max-height: 460px">
        <div v-for="b in bans" :key="b.id" class="px-3.5 py-2.5 border-b border-white/6">
          <div class="flex items-center justify-between">
            <span class="text-[12px]">{{ b.display_name || (b.account_id ? ('Account #' + b.account_id) : (b.identifier_type + ':' + b.identifier_value)) }}</span>
            <button v-if="!b.revoked_at" @click="unban(b.id)" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">UNBAN</button>
            <span v-else class="ob-mono text-[9px] text-white/30">REVOKED</span>
          </div>
          <div class="ob-mono text-[9px] text-white/35 mt-1">{{ b.reason }} · {{ b.expires_at || 'permanent' }}</div>
        </div>
        <div v-if="!bans.length" class="py-6 text-center text-[11.5px] text-white/30">No bans.</div>
      </div>
    </div>

    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between gap-1.5">
        <span class="text-[12.5px] font-medium">Warnings & kicks · {{ logs.length }}</span>
        <div class="flex gap-1.5">
          <button @click="openDraft('warn')" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ WARN</button>
          <button @click="openDraft('kick')" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ KICK</button>
        </div>
      </div>
      <div class="overflow-y-auto" style="max-height: 460px">
        <div v-for="l in logs" :key="l.id" class="px-3.5 py-2.5 border-b border-white/6">
          <div class="flex items-center gap-2">
            <span class="ob-mono text-[9px] uppercase" :style="{ color: l.type === 'kick' ? '#f87171' : '#e0b64a' }">{{ l.type }}</span>
            <span class="text-[12px]">{{ l.display_name || ('Account #' + l.account_id) }}</span>
          </div>
          <div class="ob-mono text-[9px] text-white/35 mt-1">{{ l.reason }}</div>
        </div>
        <div v-if="!logs.length" class="py-6 text-center text-[11.5px] text-white/30">No warnings or kicks.</div>
      </div>
    </div>

    <div v-if="draft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 col-span-2">
      <div class="text-[13px] font-medium capitalize">{{ draft.kind }} account</div>
      <input v-model="draft.accountId" placeholder="Account ID" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <input v-model="draft.reason" placeholder="Reason" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-if="draft.kind === 'ban'" v-model="draft.durationHours" placeholder="Duration in hours (blank = permanent)" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="draft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitDraft" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium capitalize" style="background: var(--ob-accent)">{{ draft.kind }}</button>
      </div>
    </div>
  </div>
</template>
