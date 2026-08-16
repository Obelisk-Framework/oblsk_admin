<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import Obelisk from '@/obelisk.js'

const categories = ref([])
const selectedId = ref(null)
const draft = ref(null)

const selected = () => categories.value.find(c => c.id === selectedId.value) || null

const onReply = ({ categories: next }) => { categories.value = next }

const fetchList = () => Obelisk.emit('admin:client:categories-list', {})

onMounted(() => {
  Obelisk.on('admin:client:categories-reply', onReply)
  fetchList()
})
onBeforeUnmount(() => Obelisk.off('admin:client:categories-reply', onReply))

const FIELD_TYPES = ['text', 'number', 'boolean', 'select']

const openCreate = () => { draft.value = { name: '', fields: [] } }
const openEdit = (category) => { draft.value = { id: category.id, name: category.name, fields: JSON.parse(JSON.stringify(category.fields || [])) } }

const addField = () => draft.value.fields.push({ name: '', type: 'text', required: false, options: '' })
const removeField = (i) => draft.value.fields.splice(i, 1)

const submit = () => {
  const fields = draft.value.fields.map(f => ({
    name: f.name, type: f.type, required: !!f.required,
    ...(f.type === 'select' ? { options: f.options.split(',').map(s => s.trim()).filter(Boolean) } : {}),
  }))
  if (draft.value.id) {
    Obelisk.emit('admin:client:categories-update', { categoryId: draft.value.id, attributes: { name: draft.value.name, fields } })
  } else {
    Obelisk.emit('admin:client:categories-create', { attributes: { name: draft.value.name, fields } })
  }
  draft.value = null
}

const remove = (category) => {
  Obelisk.emit('admin:client:categories-delete', { categoryId: category.id })
  if (selectedId.value === category.id) selectedId.value = null
}
</script>

<template>
  <div class="grid gap-3 min-h-0 p-5" style="grid-template-columns: 300px 1fr">
    <div class="rounded-xl border border-white/10 bg-white/[0.03] overflow-hidden flex flex-col">
      <div class="px-4 py-2.5 border-b border-white/8 flex items-center justify-between">
        <span class="text-[12.5px] font-medium">Categories · {{ categories.length }}</span>
        <button @click="openCreate" class="ob-mono text-[9px] px-1.5 py-0.5 rounded border border-white/12 hover:bg-white/8">+ NEW</button>
      </div>
      <div class="overflow-y-auto" style="max-height: 520px">
        <button v-for="c in categories" :key="c.id" @click="selectedId = c.id; openEdit(c)"
          class="w-full px-3.5 py-2.5 text-left border-b border-white/6 transition"
          :class="selectedId === c.id ? 'bg-white/[0.07]' : 'hover:bg-white/4'">
          <span class="block text-[12px] truncate">{{ c.name }}</span>
          <span class="block ob-mono text-[9px] text-white/35 truncate">{{ (c.fields || []).length }} field(s)</span>
        </button>
        <div v-if="!categories.length" class="py-6 text-center text-[11.5px] text-white/30">No categories.</div>
      </div>
    </div>

    <div v-if="draft" class="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
      <div class="text-[13px] font-medium">{{ draft.id ? 'Edit category' : 'New category' }}</div>
      <input v-model="draft.name" placeholder="Name" class="w-full h-9 px-3 rounded-lg bg-black/40 border border-white/12 text-[11.5px] outline-none" />

      <div class="space-y-2">
        <div v-for="(f, i) in draft.fields" :key="i" class="flex gap-1.5 items-center">
          <input v-model="f.name" placeholder="field_name" class="flex-1 h-8 px-2 rounded bg-black/40 border border-white/12 ob-mono text-[10.5px] outline-none" />
          <select v-model="f.type" class="h-8 px-2 rounded bg-black/40 border border-white/12 ob-mono text-[10.5px] outline-none">
            <option v-for="t in FIELD_TYPES" :key="t" :value="t">{{ t }}</option>
          </select>
          <input v-if="f.type === 'select'" v-model="f.options" placeholder="opt1, opt2" class="flex-1 h-8 px-2 rounded bg-black/40 border border-white/12 ob-mono text-[10.5px] outline-none" />
          <button @click="f.required = !f.required" class="ob-mono text-[9px] px-1.5 py-1 rounded border"
            :class="f.required ? 'border-white/30 text-black font-medium' : 'border-white/12 text-white/40'"
            :style="f.required ? { background: 'var(--ob-accent)' } : undefined">req</button>
          <button @click="removeField(i)" class="ob-mono text-[9px] px-1.5 py-1 rounded border border-white/12 text-white/40">x</button>
        </div>
        <button @click="addField" class="ob-mono text-[9px] px-2 py-1 rounded border border-white/12 hover:bg-white/8">+ field</button>
      </div>

      <div class="flex gap-2">
        <button @click="draft = null" class="h-9 px-3.5 rounded-lg border border-white/12 text-[12px]">Cancel</button>
        <button @click="submit" class="h-9 px-4 rounded-lg text-black text-[12px] font-medium" style="background: var(--ob-accent)">Save</button>
        <button v-if="draft.id" @click="remove(selected())" class="h-9 px-4 rounded-lg border border-red-500/40 text-red-400 text-[12px]">Delete</button>
      </div>
    </div>

    <div v-else class="grid place-items-center text-white/30 text-[12px]">Select or create a category.</div>
  </div>
</template>
