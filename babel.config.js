module.exports = function (api) {
  api.cache(true);
  return {
    // jsxImportSource lets NativeWind turn `className` into styles.
    // The Reanimated/worklets Babel plugin is added automatically by babel-preset-expo.
    presets: [['babel-preset-expo', { jsxImportSource: 'nativewind' }], 'nativewind/babel'],
  };
};
