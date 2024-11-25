// ./frontend/src/store/index.js
// 创建 Vuex 的 state，分别是原始数据、格式化后的全部数据、格式化后的最近24小时数据，并预先按时间顺序倒叙，以供前端组件相互传递调用，数据单位为 event

import { createStore } from 'vuex';
import dataFormatter from './src/store/dataFormatter';
import axios from 'axios'; // 引入 axios，获取config中设置的 api 链接

/**
 * 通用排序方法：按时间倒序排序
 * @param {Array} events - 需要排序的事件数组
 * @returns {Array} - 排序后的数组
 */
function sortByDateDescending(events) {
  return [...events].sort((a, b) => {
    const dateA = new Date(a.original_publication_date || a.publication_date);
    const dateB = new Date(b.original_publication_date || b.publication_date);
    return dateB - dateA; // 按时间倒序排列
  });
}

const store = createStore({
  state() {
    return {
      allEvents: [], // 全部格式化后的数据
      recentEvents: [], // 初始化 recentEvents 状态，使用 dataFormatter 格式化后的数据
      rawEvents: [],    // api 原始格式数据
    };
  },

  mutations: {
    /**
     * 设置 allEvents、recentEvents 和 rawEvents 状态，并调用通用排序方法进行排序
     * @param {Array} payload.raw - 原始数据
     * @param {Array} payload.all - 全部格式化后的数据
     * @param {Array} payload.recent - 最近 24 小时内格式化的数据
     */
    setEvents(state, { raw, all, recent }) {
      // 按时间排序（最新在前）
      state.rawEvents = sortByDateDescending(raw);
      state.allEvents = sortByDateDescending(all);
      state.recentEvents = sortByDateDescending(recent);
    },

    /**
     * 添加新事件到状态，并保持排序
     */
    addEvent(state, newEvent) {
      // 原始数据
      state.rawEvents.push(newEvent);
      state.rawEvents = sortByDateDescending(state.rawEvents);
      // 全部格式化后数据
      const formattedEvent = dataFormatter.formatEvent(newEvent);
      state.allEvents.push(formattedEvent);
      state.allEvents = this.sortByDateDescending(state.allEvents);
      // 如果新事件属于最近 24 小时，则添加到 recentEvents
      const now = new Date();
      const eventDate = new Date(newEvent.publication_date);
      if ((now - eventDate) / (1000 * 60 * 60) <= 24) {
        state.recentEvents.push(formattedEvent);
        state.recentEvents = sortByDateDescending(state.recentEvents);
      }  
    },

    /**
     * 更新事件状态，并保持排序
     */
    updateEvent(state, updatedEvent) {
      // 更新 rawEvents
      const rawIndex = state.rawEvents.findIndex(event => event._id === updatedEvent._id);
      if (rawIndex !== -1) {
        state.rawEvents[rawIndex] = updatedEvent;
        state.rawEvents = sortByDateDescending(state.rawEvents);
      }

      // 更新 allEvents
      const formattedEvent = dataFormatter.formatEvent(updatedEvent);
      const allIndex = state.allEvents.findIndex(event => event.id === updatedEvent._id);
      if (allIndex !== -1) {
        state.allEvents[allIndex] = formattedEvent;
        state.allEvents = sortByDateDescending(state.allEvents);
      }

      // 更新 recentEvents
      const recentIndex = state.recentEvents.findIndex(event => event.id === updatedEvent._id);
      if (recentIndex !== -1) {
        const now = new Date();
        const eventDate = new Date(updatedEvent.publication_date);
        if ((now - eventDate) / (1000 * 60 * 60) <= 24) {
          state.recentEvents[recentIndex] = formattedEvent;
        } else {
          state.recentEvents.splice(recentIndex, 1);
        }
        state.recentEvents = sortByDateDescending(state.recentEvents);
      }
    },

    /**
     * 从状态中删除事件
     */
    deleteEvent(state, id) {
      state.rawEvents = sortByDateDescending(state.rawEvents.filter(event => event._id !== id));
      state.allEvents = sortByDateDescending(state.allEvents.filter(event => event.id !== id));
      state.recentEvents = sortByDateDescending(state.recentEvents.filter(event => event.id !== id));
    }
  },

  actions: {
    /**
     * 获取事件数据并更新状态
     * @param {Function} commit - 用于提交 mutation
     * 通过 axios 获取最近的事件数据并更新状态
     */
    async fetchEvents({ commit }) {
      try {
        // 使用 axios 发送 GET 请求，从 API 获取事件数据
        const response = await axios.get('/api/news'); // 基于 axios.defaults.baseURL 拼接完整路径
        const events = response.data; // 获取 API 原始数据

        // 调用 dataFormatter 格式化数据
        const formattedEvents = dataFormatter.formatEvents(events);

        // 获取当前时间
        const now = new Date();

        // 过滤出最近 24 小时内的事件
        const recentEvents = formattedEvents.filter((_, index) => {
          const originalDate = new Date(formattedEvents[index].original_publication_date); // 使用格式化后的 original_publication_date
          return (now - originalDate) / (1000 * 60 * 60) <= 24;
        });

        // 更新状态
        commit('setEvents', { raw: events, all: formattedEvents, recent: recentEvents });
      } catch (error) {
        console.error("Error fetching recent events:", error);
      }
    },

    /**
     * 添加新事件
     */
    async addEvent({ commit }, newEvent) {
      try {
        const response = await axios.post('/api/admin/news', newEvent);
        if (response.status === 201 || response.status === 200) {
          commit('addEvent', response.data);
        }
      } catch (error) {
        console.error("Error adding event:", error);
      }
    },

    /**
     * 更新事件
     */
    async saveChanges({ commit }, updatedEvent) {
      try {
        const response = await axios.put(`/api/admin/news/${updatedEvent._id}`, updatedEvent);
        if (response.status === 200) {
          commit('updateEvent', response.data);
        }
      } catch (error) {
        console.error("Error saving changes:", error);
      }
    },

    /**
     * 删除事件
     */
    async deleteEvent({ commit }, id) {
      try {
        const response = await axios.delete(`/api/admin/news/${id}`);
        if (response.status === 200) {
          commit('deleteEvent', id);
        }
      } catch (error) {
        console.error("Error deleting event:", error);
      }
    }
  }
});

export default store;