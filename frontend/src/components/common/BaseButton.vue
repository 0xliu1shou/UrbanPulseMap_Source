<!-- src/components/common/BaseButton.vue -->
<template>
  <!-- 按钮元素，按钮的点击事件会通过 $emit 传递给父组件 -->
  <button :class="buttonClass" @click="handleClick" :disabled="disabled">
    <slot></slot> <!-- 插槽内容，父组件可以插入自定义文本或元素 -->
  </button>
</template>

<script>
export default {
  props: {
    type: {
      type: String,
      default: 'primary'
    },
    disabled: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    buttonClass() {
      return {
        'base-button': true,
        [`base-button--${this.type}`]: true,
      };
    }
  }
};
</script>

<style>
@import "@/styles/theme.css"; /* 导入全局主题样式，确保全局字体可用 */

.base-button--primary {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.5);
  transition: background-color 0.3s, transform 0.2s;
  font-weight: bold;
  font-size: 1em;
  font-family: "shentox", sans-serif; /* 显式指定全局字体 */
  background: var(--gradient-accent-2);
  color: var(--font-color-light);
}

/* 按钮悬停效果 */
.base-button--primary:hover {
  background: var(--gradient-accent);
  transform: scale(1.05);
}

/* 按钮激活效果 */
.base-button--primary:active {
  transform: scale(0.95);
}
</style>