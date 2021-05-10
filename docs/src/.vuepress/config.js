const { description } = require('../../package')

module.exports = {
  title: 'IoT Accelerometer Game',
  description: description,
  base: '/iot-accelerator-game/',
  themeConfig: {
    repo: 'lakermann/iot-accelerator-game',
    docsDir: '',
    sidebar: {
      '/': [
        {
          title: 'Guide',
          collapsable: false,
          children: [
            '/',
            'setup.md',
            'exercises.md',
          ]
        }
      ],
    }
  },

  /**
   * Apply plugins，ref：https://v1.vuepress.vuejs.org/zh/plugin/
   */
  plugins: [
    '@vuepress/plugin-back-to-top'
  ],
  markdown: {
    extendMarkdown: md => {
      md.use(require("markdown-it-footnote"));
    }
  }
}
