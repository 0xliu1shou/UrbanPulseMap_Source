// ./frontend/src/store/dataFormatter.js
// 用于格式化 API 返回的数据为人类可读的形式，供前端展示
/**
 * DataFormatter.js
 * 用于格式化 API 返回的数据，将 geo 数组解构成 location, latitude, 和 longitude。
 * 并去除标题和摘要的 CDATA 包裹，保留 HTML 格式。
 */
const DataFormatter = {
    /**
     *  去除 CDATA 包裹，保留 HTML 格式
     * @param {String} htmlString - 原始 HTML 字符串
     * @returns {String} - 去除 CDATA 后的 HTML 字符串
     */
    sanitizeContent(htmlString) {
        if (!htmlString) return "";
        return htmlString.replace(/<!\[CDATA\[|\]\]>/g, ""); // 去除 CDATA 标签
    },

    /**
     * 格式化日期为人类可读的形式
     * @param {string} dateString - 原始日期字符串
     * @returns {string} - 格式化后的日期
     */
    formatDate(dateString) {
        if (!dateString) return "Desconhecido"; // 返回默认值
        const date = new Date(dateString);
        const hrs = String(date.getHours()).padStart(2, "0");
        const mins = String(date.getMinutes()).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const year = date.getFullYear();
        return `${hrs}:${mins} em ${day}-${month}-${year}`;
    },

     /**
      * 转换来源简写为全称
      * @param {string} source - 来源的简写
      * @returns {string} - 来源的全称
      */
    getSourceFullName(source) {
        const sourceMap = {
            pb: "Público",
            ob: "Observador",
            rtp: "RTP",
            rc: "Record",
            cm: "Correio da Manhã",
        };
        return sourceMap[source] || "Desconhecido"; // 如果未找到对应简写，返回默认值
    },

    /**
     * 解析 geo 数组，提取纬度、经度和位置
     * @param {Array} geoArray - geo 数组
     * @returns {Object} - 包含 latitude, longitude 和 location 的对象
     */
    parseGeo(geoArray) {
        const firstGeo = geoArray?.[0] || {};
        return {
            latitude: firstGeo.latitude || null,
            longitude: firstGeo.longitude || null,
            location: firstGeo.location || "unknown",
        };
    },

    /**
     * 格式化单条数据
     * @param {Object} rawEvent - API 返回的单条事件数据
     * @returns {Object} - 格式化后的事件数据
     */
    formatEvent(rawEvent) {
        // 调取解构后的 geo 数组
        const { latitude, longitude, location } = this.parseGeo(rawEvent.geo);

        return {
            id: rawEvent._id,
            title: this.sanitizeContent(rawEvent.title || ""), // 新闻标题，去除 CDATA
            summary: this.sanitizeContent(rawEvent.summary || ""), // 新闻摘要，去除 CDATA
            publication_date: this.formatDate(rawEvent.publication_date), // 格式化日期
            source: this.getSourceFullName(rawEvent.source), // 转写来源字段为全称
            link: rawEvent.link || "",
            event: rawEvent.event || "unknown",
            location,
            latitude,
            longitude,
            time: rawEvent.time || "",
            original_publication_date: rawEvent.publication_date, // 保留原始日期
        };
    },

    /**
     * 格式化一组数据
     * @param {Array} rawEvents - API 返回的事件数据数组
     * @returns {Array} - 格式化后的事件数据数组
     */
    formatEvents(rawEvents) {
        return rawEvents.map((event) => this.formatEvent(event));
    },
};

export default DataFormatter;