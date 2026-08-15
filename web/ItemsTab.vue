<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, watch } from 'vue'
import Obelisk from '@/obelisk.js'

const items = ref([])
const selectedId = ref(null)
const createDraft = ref(null)
const giveDraft = ref(null)

const selected = computed(() => items.value.find(i => i.id === selectedId.value) || null)

const DEV_ITEMS = [
  { id: 1, name: 'water', description: 'A bottle of water', icon: 'water', weight: 0.5, is_takeable: 1, is_giveable: 1, is_dropable: 1, is_container: 0, is_useable: 1, is_stackable: 1, max_stack_amount: 10 },
  { id: 2, name: 'bandage', description: 'Stops bleeding', icon: 'bandage', weight: 0.2, is_takeable: 1, is_giveable: 1, is_dropable: 1, is_container: 0, is_useable: 1, is_stackable: 1, max_stack_amount: 5 },
]

const onReply = ({ items: next }) => { items.value = next }

const fetchList = () => {
  if (import.meta.env.DEV) { items.value = DEV_ITEMS; return }
  Obelisk.emit('admin:client:items-list', {})
}

onMounted(() => {
  Obelisk.on('admin:client:items-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:items-reply', onReply))

const registry = inject('obelisk:globalElementsRegistry', null)
if (registry) {
  watch(() => registry.get('admin')?.visible, (visible) => { if (visible) fetchList() })
}

const FLAGS = ['is_takeable', 'is_giveable', 'is_dropable', 'is_container', 'is_useable', 'is_stackable']

const updateField = (item, field, value) => {
  Obelisk.emit('admin:client:items-update', { baseItemId: item.id, attributes: { [field]: value } })
}
const toggleFlag = (item, flag) => updateField(item, flag, item[flag] ? 0 : 1)

const openCreate = () => { createDraft.value = { name: '', description: '', weight: 0, max_stack_amount: 1, bindingKey: '' } }
const submitCreate = () => {
  const { bindingKey, ...attributes } = createDraft.value
  Obelisk.emit('admin:client:items-create', { attributes, bindingKey: bindingKey || null })
  createDraft.value = null
}

const openGive = (item) => { giveDraft.value = { item, targetSource: '', amount: 1 } }
const submitGive = () => {
  Obelisk.emit('admin:client:items-give', { targetSource: Number(giveDraft.value.targetSource), baseItemId: giveDraft.value.item.id, amount: Number(giveDraft.value.amount) })
  giveDraft.value = null
}
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 300px 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Items · {{ items.length }}</span>
        <button @click="openCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
      </div>
      <div class="overflow-y-auto" style="max-height: 520px">
        <button v-for="i in items" :key="i.id" @click="selectedId = i.id"
          class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
          :class="selectedId === i.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
          <span class="block text-[12px] truncate">{{ i.name }}</span>
          <span class="block ob-mono text-[9px] text-white/35 truncate">{{ i.weight }}kg · stack {{ i.max_stack_amount || 1 }}</span>
        </button>
        <div v-if="!items.length" class="py-6 text-center text-[11.5px] text-white/30">No items.</div>
      </div>
    </div>

    <div v-if="createDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div class="text-[13px] font-medium">New item</div>
      <input v-model="createDraft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-model="createDraft.description" placeholder="Description" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      <input v-model.number="createDraft.weight" type="number" step="0.1" placeholder="Weight" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <input v-model="createDraft.bindingKey" placeholder="Binding key (optional, e.g. fishing.rod)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="createDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitCreate" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Create item</button>
      </div>
    </div>

    <div v-else-if="selected" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div>
        <div class="ob-mono text-[9px] tracking-[0.2em] text-white/30 uppercase mb-1.5">Description</div>
        <input :value="selected.description" @change="updateField(selected, 'description', $event.target.value)" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />
      </div>
      <div class="flex flex-wrap gap-1.5">
        <button v-for="flag in FLAGS" :key="flag" @click="toggleFlag(selected, flag)"
          class="ob-mono text-[9px] px-2 py-1 rounded border"
          :class="selected[flag] ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40'"
          :style="selected[flag] ? { background: 'var(--ob-accent)' } : undefined">{{ flag.replace('is_', '') }}</button>
      </div>
      <div class="pt-2">
        <button @click="openGive(selected)" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Give to player</button>
      </div>
    </div>

    <div v-else class="grid place-items-center text-white/30 text-[12px]">No item selected.</div>

    <div v-if="giveDraft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3 col-span-2">
      <div class="text-[13px] font-medium">Give {{ giveDraft.item.name }}</div>
      <input v-model="giveDraft.targetSource" placeholder="Player server ID" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <input v-model="giveDraft.amount" placeholder="Amount" type="number" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 ob-mono text-[11.5px] outline-none" />
      <div class="flex gap-2">
        <button @click="giveDraft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submitGive" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Give</button>
      </div>
    </div>
  </div>
</template>