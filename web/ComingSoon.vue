<script setup>
defineProps({ label: { type: String, required: true } })
</script>

<template>
  <div class="flex-1 grid place-items-center text-white/30">
    <div class="text-center">
      <div class="text-[13px]">{{ label }}</div>
      <div class="ob-mono text-[10px] mt-1 text-white/20">COMING SOON</div>
    </div>
  </div>
</template>
