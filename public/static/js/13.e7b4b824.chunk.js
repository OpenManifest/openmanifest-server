(this.webpackJsonp=this.webpackJsonp||[]).push([[13,23],{194:function(e,t,n){"use strict";n.d(t,"a",(function(){return r}));var r={};n.r(r),n.d(r,"Accordion",(function(){return w})),n.d(r,"AccordionGroup",(function(){return g})),n.d(r,"Icon",(function(){return x})),n.d(r,"Item",(function(){return z})),n.d(r,"Section",(function(){return q})),n.d(r,"Subheader",(function(){return W}));var i=n(6),a=n.n(i),o=n(33),c=n.n(o),s=n(0),l=n(5),u=n(4),p=n(31),d=n(193),h=n(87),f=n(119),y=n(38),m=s.createContext(null),b=function(e){var t=e.expandedId,n=e.onAccordionPress,r=e.children,i=s.useState(void 0),o=a()(i,2),c=o[0],l=o[1];return s.createElement(m.Provider,{value:{expandedId:t||c,onAccordionPress:n||function(e){l((function(t){return t===e?void 0:e}))}}},r)};b.displayName="List.AccordionGroup";var g=b,v=function(e){var t=e.left,n=e.right,r=e.title,i=e.description,o=e.children,u=e.theme,y=e.titleStyle,b=e.descriptionStyle,g=e.titleNumberOfLines,v=void 0===g?1:g,w=e.descriptionNumberOfLines,j=void 0===w?2:w,E=e.style,P=e.id,x=e.testID,L=e.onPress,D=e.onLongPress,S=e.expanded,R=s.useState(S||!1),C=a()(R,2),k=C[0],I=C[1],V=c()(u.colors.text).alpha(.87).rgb().string(),N=c()(u.colors.text).alpha(.54).rgb().string(),z=void 0!==S?S:k,A=s.useContext(m);if(null!==A&&!P)throw new Error("List.Accordion is used inside a List.AccordionGroup without specifying an id prop.");var M=A?A.expandedId===P:z,T=A&&void 0!==P?function(){return A.onAccordionPress(P)}:function(){null===L||void 0===L||L(),void 0===S&&I((function(e){return!e}))};return s.createElement(l.a,null,s.createElement(d.a,{style:[O.container,E],onPress:T,onLongPress:D,accessibilityTraits:"button",accessibilityComponentType:"button",accessibilityRole:"button",testID:x,borderless:!0},s.createElement(l.a,{style:O.row,pointerEvents:"none"},t?t({color:M?u.colors.primary:N}):null,s.createElement(l.a,{style:[O.item,O.content]},s.createElement(f.a,{selectable:!1,numberOfLines:v,style:[O.title,{color:M?u.colors.primary:V},y]},r),i&&s.createElement(f.a,{selectable:!1,numberOfLines:j,style:[O.description,{color:N},b]},i)),s.createElement(l.a,{style:[O.item,i?O.multiline:void 0]},n?n({isExpanded:M}):s.createElement(h.b,{name:M?"chevron-up":"chevron-down",color:V,size:24,direction:p.a.isRTL?"rtl":"ltr"})))),M?s.Children.map(o,(function(e){return t&&s.isValidElement(e)&&!e.props.left&&!e.props.right?s.cloneElement(e,{style:[O.child,e.props.style]}):e})):null)};v.displayName="List.Accordion";var O=u.a.create({container:{padding:8},row:{flexDirection:"row",alignItems:"center"},multiline:{height:40,alignItems:"center",justifyContent:"center"},title:{fontSize:16},description:{fontSize:14},item:{margin:8},child:{paddingLeft:64},content:{flex:1,justifyContent:"center"}}),w=Object(y.c)(v),j=n(195),E=function(e){var t=e.icon,n=e.color,r=e.style;return s.createElement(l.a,{style:[P.item,r],pointerEvents:"box-none"},s.createElement(j.a,{source:t,size:24,color:n}))},P=u.a.create({item:{margin:8,height:40,width:40,alignItems:"center",justifyContent:"center"}});E.displayName="List.Icon";var x=E,L=n(7),D=n.n(L),S=n(13),R=n.n(S);function C(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function k(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?C(Object(n),!0).forEach((function(t){D()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):C(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function I(){return(I=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var V=function(e){var t=e.left,n=e.right,r=e.title,i=e.description,a=e.onPress,o=e.theme,u=e.style,p=e.titleStyle,h=e.titleNumberOfLines,y=void 0===h?1:h,m=e.descriptionNumberOfLines,b=void 0===m?2:m,g=e.titleEllipsizeMode,v=e.descriptionEllipsizeMode,O=e.descriptionStyle,w=R()(e,["left","right","title","description","onPress","theme","style","titleStyle","titleNumberOfLines","descriptionNumberOfLines","titleEllipsizeMode","descriptionEllipsizeMode","descriptionStyle"]),j=c()(o.colors.text).alpha(.87).rgb().string(),E=c()(o.colors.text).alpha(.54).rgb().string();return s.createElement(d.a,I({},w,{style:[N.container,u],onPress:a}),s.createElement(l.a,{style:N.row},t?t({color:E,style:i?N.iconMarginLeft:k(k({},N.iconMarginLeft),N.marginVerticalNone)}):null,s.createElement(l.a,{style:[N.item,N.content]},s.createElement(f.a,{selectable:!1,ellipsizeMode:g,numberOfLines:y,style:[N.title,{color:j},p]},r),i?function(e,t){return"function"===typeof t?t({selectable:!1,ellipsizeMode:v,color:e,fontSize:N.description.fontSize}):s.createElement(f.a,{selectable:!1,numberOfLines:b,ellipsizeMode:v,style:[N.description,{color:e},O]},t)}(E,i):null),n?n({color:E,style:i?N.iconMarginRight:k(k({},N.iconMarginRight),N.marginVerticalNone)}):null))};V.displayName="List.Item";var N=u.a.create({container:{padding:8},row:{flexDirection:"row"},title:{fontSize:16},description:{fontSize:14},marginVerticalNone:{marginVertical:0},iconMarginLeft:{marginLeft:0,marginRight:16},iconMarginRight:{marginRight:0},item:{marginVertical:6,paddingLeft:8},content:{flex:1,justifyContent:"center"}}),z=Object(y.c)(V);function A(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function M(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?A(Object(n),!0).forEach((function(t){D()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):A(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function T(){return(T=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var H=function(e){var t=e.style,n=e.theme,r=R()(e,["style","theme"]),i=n.colors,a=n.fonts.medium,o=c()(i.text).alpha(.54).rgb().string();return s.createElement(f.a,T({numberOfLines:1},r,{style:[B.container,M({color:o},a),t]}))};H.displayName="List.Subheader";var B=u.a.create({container:{paddingHorizontal:16,paddingVertical:13}}),W=Object(y.c)(H);function F(){return(F=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var G=function(e){var t=e.children,n=e.title,r=e.titleStyle,i=e.style,a=R()(e,["children","title","titleStyle","style"]);return s.createElement(l.a,F({},a,{style:[U.container,i]}),n?s.createElement(W,{style:r},n):null,t)};G.displayName="List.Section";var U=u.a.create({container:{marginVertical:8}}),q=Object(y.c)(G)},406:function(e,t,n){"use strict";var r=n(13),i=n.n(r),a=n(0),o=n(5),c=n(4),s=n(33),l=n.n(s),u=n(193),p=n(195),d=n(424),h=n(38);function f(){return(f=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var y=c.a.create({container:{alignItems:"center",justifyContent:"center",overflow:"hidden",margin:6},disabled:{opacity:.32}});t.a=Object(h.c)((function(e){var t=e.icon,n=e.color,r=e.size,c=void 0===r?24:r,s=e.accessibilityLabel,h=e.disabled,m=e.onPress,b=e.animated,g=void 0!==b&&b,v=e.theme,O=e.style,w=i()(e,["icon","color","size","accessibilityLabel","disabled","onPress","animated","theme","style"]),j="undefined"!==typeof n?n:v.colors.text,E=l()(j).alpha(.32).rgb().string(),P=g?d.a:p.a,x=1.5*c;return a.createElement(u.a,f({borderless:!0,centered:!0,onPress:m,rippleColor:E,style:[y.container,{width:x,height:x,borderRadius:x/2},h&&y.disabled,O],accessibilityLabel:s,accessibilityTraits:h?["button","disabled"]:"button",accessibilityComponentType:"button",accessibilityRole:"button",accessibilityState:{disabled:h},disabled:h,hitSlop:u.a.supported?{top:10,left:10,bottom:10,right:10}:{top:6,left:6,bottom:6,right:6}},w),a.createElement(o.a,null,a.createElement(P,{color:j,source:t,size:c})))}))},407:function(e,t,n){"use strict";var r=n(0),i=n(4),a=n(418);function o(){return(o=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}t.a=function(e){return r.createElement(a.a,o({},e,{alpha:.87,family:"medium",style:[c.text,e.style]}))};var c=i.a.create({text:{fontSize:20,lineHeight:30,marginVertical:2,letterSpacing:.15}})},410:function(e,t,n){"use strict";var r=n(0),i=n(4),a=n(418);function o(){return(o=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}t.a=function(e){return r.createElement(a.a,o({},e,{alpha:.54,family:"regular",style:[c.text,e.style]}))};var c=i.a.create({text:{fontSize:12,lineHeight:20,marginVertical:2,letterSpacing:.4}})},411:function(e,t,n){"use strict";var r=n(13),i=n.n(r),a=n(0),o=n(4),c=n(8),s=n(196),l=n(5);function u(){return(u=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var p=function(e){var t,n,r,o=e.index,c=e.total,s=e.siblings,p=e.style,h=i()(e,["index","total","siblings","style"]),f="withTheme(CardCover)",y="withTheme(CardTitle)";return"number"===typeof o&&s&&(n=s[o-1],r=s[o+1]),n===f&&r===f||n===y&&r===y||1===c?t=d.only:0===o?t=r===f||r===y?d.only:d.first:"number"===typeof c&&o===c-1?t=n===f||n===y?d.only:d.last:n===f||n===y?t=d.first:r!==f&&r!==y||(t=d.last),a.createElement(l.a,u({},h,{style:[d.container,t,p]}))};p.displayName="Card.Content";var d=o.a.create({container:{paddingHorizontal:16},first:{paddingTop:16},last:{paddingBottom:16},only:{paddingVertical:16}}),h=p;function f(){return(f=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var y=function(e){return a.createElement(l.a,f({},e,{style:[m.container,e.style]}),a.Children.map(e.children,(function(e){return a.isValidElement(e)?a.cloneElement(e,{compact:!1!==e.props.compact}):e})))};y.displayName="Card.Actions";var m=o.a.create({container:{flexDirection:"row",alignItems:"center",justifyContent:"flex-start",padding:8}}),b=y,g=n(83),v=n(38),O=n(32);function w(){return(w=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var j=function(e){var t,n=e.index,r=e.total,o=e.style,c=e.theme,s=i()(e,["index","total","style","theme"]),u=c.roundness;return 0===n?t=1===r?{borderRadius:u}:{borderTopLeftRadius:u,borderTopRightRadius:u}:"number"===typeof r&&n===r-1&&(t={borderBottomLeftRadius:u}),a.createElement(l.a,{style:[E.container,t,o]},a.createElement(g.a,w({},s,{style:[E.image,t]})))};j.displayName="Card.Cover";var E=o.a.create({container:{height:195,backgroundColor:O.b,overflow:"hidden"},image:{flex:1,height:void 0,width:void 0,padding:16,justifyContent:"flex-end"}}),P=Object(v.c)(j),x=n(410),L=n(407),D=function(e){var t=e.title,n=e.titleStyle,r=e.titleNumberOfLines,i=void 0===r?1:r,o=e.subtitle,c=e.subtitleStyle,s=e.subtitleNumberOfLines,u=void 0===s?1:s,p=e.left,d=e.leftStyle,h=e.right,f=e.rightStyle,y=e.style;return a.createElement(l.a,{style:[S.container,{minHeight:o||p||h?72:50},y]},p?a.createElement(l.a,{style:[S.left,d]},p({size:40})):null,a.createElement(l.a,{style:[S.titles]},t?a.createElement(L.a,{style:[S.title,{marginBottom:o?0:2},n],numberOfLines:i},t):null,o?a.createElement(x.a,{style:[S.subtitle,c],numberOfLines:u},o):null),a.createElement(l.a,{style:f},h?h({size:24}):null))};D.displayName="Card.Title";var S=o.a.create({container:{flexDirection:"row",alignItems:"center",justifyContent:"space-between",paddingLeft:16},left:{justifyContent:"center",marginRight:16,height:40,width:40},titles:{flex:1,flexDirection:"column",justifyContent:"center"},title:{minHeight:30},subtitle:{minHeight:20,marginVertical:0}}),R=Object(v.c)(D),C=n(121);function k(){return(k=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var I=function(e){var t=e.elevation,n=void 0===t?1:t,r=e.onLongPress,o=e.onPress,u=e.children,p=e.style,d=e.theme,h=e.testID,f=e.accessible,y=i()(e,["elevation","onLongPress","onPress","children","style","theme","testID","accessible"]),m=a.useRef(new c.a.Value(n)).current,b=d.roundness,g=a.Children.count(u),v=a.Children.map(u,(function(e){return a.isValidElement(e)&&e.type?e.type.displayName:null}));return a.createElement(C.a,k({style:[{borderRadius:b,elevation:m},p]},y),a.createElement(s.a,{delayPressIn:0,disabled:!(o||r),onLongPress:r,onPress:o,onPressIn:o?function(){var e=d.dark,t=d.mode,n=d.animation.scale;c.a.timing(m,{toValue:8,duration:150*n,useNativeDriver:!e||"exact"===t}).start()}:void 0,onPressOut:o?function(){var e=d.dark,t=d.mode,r=d.animation.scale;c.a.timing(m,{toValue:n,duration:150*r,useNativeDriver:!e||"exact"===t}).start()}:void 0,testID:h,accessible:f},a.createElement(l.a,{style:V.innerContainer},a.Children.map(u,(function(e,t){return a.isValidElement(e)?a.cloneElement(e,{index:t,total:g,siblings:v}):e})))))};I.Content=h,I.Actions=b,I.Cover=P,I.Title=R;var V=o.a.create({innerContainer:{flexGrow:1,flexShrink:1}});t.a=Object(v.c)(I)},413:function(e,t,n){"use strict";var r=n(21),i=n.n(r),a=n(30),o=n.n(a),c=n(24),s=n.n(c),l=n(25),u=n.n(l),p=n(15),d=n.n(p),h=n(0),f=n(12),y=n.n(f),m=n(10),b=n.n(m);function g(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}function v(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var O=function(e){s()(r,e);var t,n=(t=r,function(){var e,n=d()(t);if(g()){var r=d()(this).constructor;e=Reflect.construct(n,arguments,r)}else e=n.apply(this,arguments);return u()(this,e)});function r(){var e;i()(this,r);for(var t=arguments.length,a=new Array(t),o=0;o<t;o++)a[o]=arguments[o];return e=n.call.apply(n,[this].concat(a)),v(y()(e),"key",void 0),e}return o()(r,[{key:"componentDidMount",value:function(){return b.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return this.checkManager(),e.next=3,b.a.awrap(Promise.resolve());case 3:this.key=this.props.manager.mount(this.props.children);case 4:case"end":return e.stop()}}),null,this,null,Promise)}},{key:"componentDidUpdate",value:function(){this.checkManager(),this.props.manager.update(this.key,this.props.children)}},{key:"componentWillUnmount",value:function(){this.checkManager(),this.props.manager.unmount(this.key)}},{key:"checkManager",value:function(){if(!this.props.manager)throw new Error("Looks like you forgot to wrap your root component with `Provider` component from `react-native-paper`.\n\nPlease read our getting-started guide and make sure you've followed all the required steps.\n\nhttps://callstack.github.io/react-native-paper/getting-started.html")}},{key:"render",value:function(){return null}}]),r}(h.Component),w=n(211),j=n(123),E=n(38);function P(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}var x,L,D,S=function(e){s()(r,e);var t,n=(t=r,function(){var e,n=d()(t);if(P()){var r=d()(this).constructor;e=Reflect.construct(n,arguments,r)}else e=n.apply(this,arguments);return u()(this,e)});function r(){return i()(this,r),n.apply(this,arguments)}return o()(r,[{key:"render",value:function(){var e=this.props,t=e.children,n=e.theme;return h.createElement(j.a,null,(function(e){return h.createElement(w.a.Consumer,null,(function(r){return h.createElement(O,{manager:r},h.createElement(j.b,{value:e},h.createElement(E.a,{theme:n},t)))}))}))}}]),r}(h.Component);x=S,L="Host",D=w.b,L in x?Object.defineProperty(x,L,{value:D,enumerable:!0,configurable:!0,writable:!0}):x[L]=D;t.a=Object(E.c)(S)},416:function(e,t,n){"use strict";var r=n(27),i=n.n(r),a=n(0),o=n(11),c=n(13),s=n.n(c),l=n(4),u=n(5),p=n(33),d=n.n(p),h=n(87),f=n(193),y=n(38);function m(){return(m=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var b=function(e){var t,n=e.status,r=e.disabled,i=e.onPress,o=e.theme,c=e.testID,l=s()(e,["status","disabled","onPress","theme","testID"]),p="checked"===n,y="indeterminate"===n,b=r?o.colors.disabled:l.color||o.colors.accent;t=r?d()(o.colors.text).alpha(.16).rgb().string():d()(b).fade(.32).rgb().string();var v=y?"minus":"check";return a.createElement(f.a,m({},l,{borderless:!0,rippleColor:t,onPress:i,disabled:r,accessibilityTraits:r?["button","disabled"]:"button",accessibilityComponentType:"button",accessibilityRole:"checkbox",accessibilityState:{disabled:r,checked:p},accessibilityLiveRegion:"polite",style:g.container,testID:c}),a.createElement(u.a,{style:{opacity:y||p?1:0}},a.createElement(h.b,{allowFontScaling:!1,name:v,size:24,color:b,direction:"ltr"})))};b.displayName="Checkbox.IOS";var g=l.a.create({container:{borderRadius:18,padding:6}}),v=Object(y.c)(b),O=(Object(y.c)(b),n(8));function w(){return(w=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var j=function(e){var t=e.status,n=e.theme,r=e.disabled,i=e.onPress,o=e.testID,c=s()(e,["status","theme","disabled","onPress","testID"]),p=a.useRef(new O.a.Value(1)).current,y=a.useRef(!0),m=n.animation.scale;a.useEffect((function(){if(y.current)y.current=!1;else{var e="checked"===t;O.a.sequence([O.a.timing(p,{toValue:.85,duration:e?100*m:0,useNativeDriver:!1}),O.a.timing(p,{toValue:1,duration:e?100*m:100*m*1.75,useNativeDriver:!1})]).start()}}),[t,p,m]);var b,g,v="checked"===t,j="indeterminate"===t,P=c.color||n.colors.accent,x=c.uncheckedColor||d()(n.colors.text).alpha(n.dark?.7:.54).rgb().string();r?(b=d()(n.colors.text).alpha(.16).rgb().string(),g=n.colors.disabled):(b=d()(P).fade(.32).rgb().string(),g=v?P:x);var L=p.interpolate({inputRange:[.8,1],outputRange:[7,0]}),D=j?"minus-box":v?"checkbox-marked":"checkbox-blank-outline";return a.createElement(f.a,w({},c,{borderless:!0,rippleColor:b,onPress:i,disabled:r,accessibilityTraits:r?["button","disabled"]:"button",accessibilityComponentType:"button",accessibilityRole:"checkbox",accessibilityState:{disabled:r,checked:v},accessibilityLiveRegion:"polite",style:E.container,testID:o}),a.createElement(O.a.View,{style:{transform:[{scale:p}]}},a.createElement(h.b,{allowFontScaling:!1,name:D,size:24,color:g,direction:"ltr"}),a.createElement(u.a,{style:[l.a.absoluteFill,E.fillContainer]},a.createElement(O.a.View,{style:[E.fill,{borderColor:g},{borderWidth:L}]}))))};j.displayName="Checkbox.Android";var E=l.a.create({container:{borderRadius:18,width:36,height:36,padding:6},fillContainer:{alignItems:"center",justifyContent:"center"},fill:{height:14,width:14}}),P=Object(y.c)(j),x=(Object(y.c)(j),function(e){return"ios"===o.a.OS?a.createElement(v,e):a.createElement(P,e)}),L=Object(y.c)(x),D=(Object(y.c)(x),n(7)),S=n.n(D),R=n(119);function C(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function k(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?C(Object(n),!0).forEach((function(t){S()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):C(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var I=function(e){var t,n=e.style,r=e.status,i=e.label,o=e.onPress,c=e.labelStyle,l=e.theme,p=e.testID,d=e.mode,h=k(k({},s()(e,["style","status","label","onPress","labelStyle","theme","testID","mode"])),{},{status:r,theme:l});return t="android"===d?a.createElement(P,h):"ios"===d?a.createElement(v,h):a.createElement(L,h),a.createElement(f.a,{onPress:o,testID:p},a.createElement(u.a,{style:[N.container,n],pointerEvents:"none"},a.createElement(R.a,{style:[N.label,{color:l.colors.text},c]},i),t))};I.displayName="Checkbox.Item";var V=Object(y.c)(I),N=(Object(y.c)(I),l.a.create({container:{flexDirection:"row",alignItems:"center",justifyContent:"space-between",paddingVertical:8,paddingHorizontal:16},label:{fontSize:16,flexShrink:1,flexGrow:1}})),z=i()(L,{Item:V,Android:P,IOS:v});t.a=z},418:function(e,t,n){"use strict";var r=n(7),i=n.n(r),a=n(13),o=n.n(a),c=n(33),s=n.n(c),l=n(0),u=n(31),p=n(4),d=n(119),h=n(38);function f(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function y(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?f(Object(n),!0).forEach((function(t){i()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):f(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function m(){return(m=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var r in n)Object.prototype.hasOwnProperty.call(n,r)&&(e[r]=n[r])}return e}).apply(this,arguments)}var b=p.a.create({text:{textAlign:"left"}});t.a=Object(h.c)((function(e){var t=e.theme,n=e.alpha,r=e.family,i=e.style,a=o()(e,["theme","alpha","family","style"]),c=s()(t.colors.text).alpha(n).rgb().string(),p=t.fonts[r],h=u.a.isRTL?"rtl":"ltr";return l.createElement(d.a,m({},a,{style:[b.text,y(y({color:c},p),{},{writingDirection:h}),i]}))}))},419:function(e,t,n){"use strict";(function(e){var r=n(7),i=n.n(r),a=n(6),o=n.n(a),c=n(21),s=n.n(c),l=n(30),u=n.n(l),p=n(12),d=n.n(p),h=n(24),f=n.n(h),y=n(25),m=n.n(y),b=n(15),g=n.n(b),v=n(10),O=n.n(v),w=n(0),j=n(11),E=n(4),P=n(8),x=n(206),L=n(53),D=n(62),S=n(31),R=n(196),C=n(5),k=n(89),I=n(61),V=n(38),N=n(413),z=n(121),A=n(446),M=n(443);function T(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function H(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?T(Object(n),!0).forEach((function(t){i()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):T(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function B(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],(function(){}))),!0}catch(e){return!1}}function W(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var F=D.a.bezier(.4,0,.2,1),G=function(t){f()(i,t);var n,r=(n=i,function(){var e,t=g()(n);if(B()){var r=g()(this).constructor;e=Reflect.construct(t,arguments,r)}else e=t.apply(this,arguments);return m()(this,e)});function i(){var t;s()(this,i);for(var n=arguments.length,a=new Array(n),c=0;c<n;c++)a[c]=arguments[c];return t=r.call.apply(r,[this].concat(a)),W(d()(t),"state",{rendered:t.props.visible,top:0,left:0,menuLayout:{width:0,height:0},anchorLayout:{width:0,height:0},opacityAnimation:new P.a.Value(0),scaleAnimation:new P.a.ValueXY({x:0,y:0})}),W(d()(t),"anchor",null),W(d()(t),"menu",null),W(d()(t),"isCoordinate",(function(e){return!w.isValidElement(e)&&"number"===typeof(null===e||void 0===e?void 0:e.x)&&"number"===typeof(null===e||void 0===e?void 0:e.y)})),W(d()(t),"measureMenuLayout",(function(){return new Promise((function(e){t.menu&&t.menu.measureInWindow((function(t,n,r,i){e({x:t,y:n,width:r,height:i})}))}))})),W(d()(t),"measureAnchorLayout",(function(){return new Promise((function(e){var n=t.props.anchor;t.isCoordinate(n)?e({x:n.x,y:n.y,width:0,height:0}):t.anchor&&t.anchor.measureInWindow((function(t,n,r,i){e({x:t,y:n,width:r,height:i})}))}))})),W(d()(t),"updateVisibility",(function(){return O.a.async((function(e){for(;;)switch(e.prev=e.next){case 0:return e.next=2,O.a.awrap(Promise.resolve());case 2:t.props.visible?t.show():t.hide();case 3:case"end":return e.stop()}}),null,null,null,Promise)})),W(d()(t),"isBrowser",(function(){return"web"===j.a.OS&&"document"in e})),W(d()(t),"focusFirstDOMNode",(function(e){if(e&&t.isBrowser()){var n=Object(I.a)(e).querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');null===n||void 0===n||n.focus()}})),W(d()(t),"handleDismiss",(function(){return t.props.visible&&t.props.onDismiss(),!0})),W(d()(t),"handleKeypress",(function(e){"Escape"===e.key&&t.props.onDismiss()})),W(d()(t),"attachListeners",(function(){x.a.addEventListener("hardwareBackPress",t.handleDismiss),L.a.addEventListener("change",t.handleDismiss),t.isBrowser()&&document.addEventListener("keyup",t.handleKeypress)})),W(d()(t),"removeListeners",(function(){x.a.removeEventListener("hardwareBackPress",t.handleDismiss),L.a.removeEventListener("change",t.handleDismiss),t.isBrowser()&&document.removeEventListener("keyup",t.handleKeypress)})),W(d()(t),"show",(function(){var e,n,r,i,a;return O.a.async((function(c){for(;;)switch(c.prev=c.next){case 0:return e=L.a.get("window"),c.next=3,O.a.awrap(Promise.all([t.measureMenuLayout(),t.measureAnchorLayout()]));case 3:if(n=c.sent,r=o()(n,2),i=r[0],a=r[1],e.width&&e.height&&i.width&&i.height&&(a.width||t.isCoordinate(t.props.anchor))&&(a.height||t.isCoordinate(t.props.anchor))){c.next=10;break}return requestAnimationFrame(t.show),c.abrupt("return");case 10:t.setState((function(){return{left:a.x,top:a.y,anchorLayout:{height:a.height,width:a.width},menuLayout:{width:i.width,height:i.height}}}),(function(){t.attachListeners();var e=t.props.theme.animation;P.a.parallel([P.a.timing(t.state.scaleAnimation,{toValue:{x:i.width,y:i.height},duration:250*e.scale,easing:F,useNativeDriver:!0}),P.a.timing(t.state.opacityAnimation,{toValue:1,duration:250*e.scale,easing:F,useNativeDriver:!0})]).start((function(e){e.finished&&t.focusFirstDOMNode(t.menu)}))}));case 11:case"end":return c.stop()}}),null,null,null,Promise)})),W(d()(t),"hide",(function(){t.removeListeners();var e=t.props.theme.animation;P.a.timing(t.state.opacityAnimation,{toValue:0,duration:250*e.scale,easing:F,useNativeDriver:!0}).start((function(e){e.finished&&(t.setState({menuLayout:{width:0,height:0},rendered:!1}),t.state.scaleAnimation.setValue({x:0,y:0}),t.focusFirstDOMNode(t.anchor))}))})),t}return u()(i,[{key:"componentDidUpdate",value:function(e){e.visible!==this.props.visible&&this.updateVisibility()}},{key:"componentWillUnmount",value:function(){this.removeListeners()}},{key:"render",value:function(){var e=this,t=this.props,n=t.visible,r=t.anchor,i=t.contentStyle,a=t.style,o=t.children,c=t.theme,s=t.statusBarHeight,l=t.onDismiss,u=t.overlayAccessibilityLabel,p=this.state,d=p.rendered,h=p.menuLayout,f=p.anchorLayout,y=p.opacityAnimation,m=p.scaleAnimation,b=this.state,g=b.left,v=b.top,O=j.a.select({android:s,default:0}),x=[{scaleX:m.x.interpolate({inputRange:[0,h.width],outputRange:[0,1]})},{scaleY:m.y.interpolate({inputRange:[0,h.height],outputRange:[0,1]})}],D=L.a.get("window"),I=[];g<=D.width-h.width-8?(I.push({translateX:m.x.interpolate({inputRange:[0,h.width],outputRange:[-h.width/2,0]})}),g<8&&(g=8)):(I.push({translateX:m.x.interpolate({inputRange:[0,h.width],outputRange:[h.width/2,0]})}),(g+=f.width-h.width)+h.width>D.width-8&&(g=D.width-8-h.width));var V=0;(v>=D.height-h.height-8-O&&v<=D.height-v?V=D.height-v-8-O:v>=D.height-h.height-8-O&&v>=D.height-v&&v<=h.height-f.height+8-O&&(V=v+f.height-8+O),V=V>D.height-16?D.height-16:V,v<=D.height-h.height-8-O||v>=D.height-h.height-8-O&&v<=D.height-v)?(I.push({translateY:m.y.interpolate({inputRange:[0,h.height],outputRange:[-(V||h.height)/2,0]})}),v<8&&(v=8)):(I.push({translateY:m.y.interpolate({inputRange:[0,h.height],outputRange:[(V||h.height)/2,0]})}),(v+=f.height-(V||h.height))+(V||h.height)+O>D.height-8&&(v=V===D.height-16?-16:D.height-h.height-8-O));var A=H({opacity:y,transform:x,borderRadius:c.roundness},V?{height:V}:{}),M=H({top:this.isCoordinate(r)?v:v+O},S.a.isRTL?{right:g}:{left:g});return w.createElement(C.a,{ref:function(t){e.anchor=t},collapsable:!1},this.isCoordinate(r)?null:r,d?w.createElement(N.a,null,w.createElement(R.a,{accessibilityLabel:u,accessibilityRole:"button",onPress:l},w.createElement(C.a,{style:E.a.absoluteFill})),w.createElement(C.a,{ref:function(t){e.menu=t},collapsable:!1,accessibilityViewIsModal:n,style:[U.wrapper,M,a],pointerEvents:n?"box-none":"none",onAccessibilityEscape:l},w.createElement(P.a.View,{style:{transform:I}},w.createElement(z.a,{style:[U.shadowMenuContainer,A,i]},V&&w.createElement(k.a,null,o)||w.createElement(w.Fragment,null,o))))):null)}}],[{key:"getDerivedStateFromProps",value:function(e,t){return e.visible&&!t.rendered?{rendered:!0}:null}}]),i}(w.Component);W(G,"Item",A.a),W(G,"defaultProps",{statusBarHeight:M.a,overlayAccessibilityLabel:"Close menu"});var U=E.a.create({wrapper:{position:"absolute"},shadowMenuContainer:{opacity:0,paddingVertical:8,elevation:8}});t.a=Object(V.c)(G)}).call(this,n(74))},424:function(e,t,n){"use strict";var r=n(6),i=n.n(r),a=n(0),o=n(8),c=n(4),s=n(5),l=n(195),u=n(38);t.a=Object(u.c)((function(e){var t=e.color,n=e.size,r=e.source,c=e.theme,u=a.useState((function(){return r})),d=i()(u,2),h=d[0],f=d[1],y=a.useState(null),m=i()(y,2),b=m[0],g=m[1],v=a.useRef(new o.a.Value(1)).current,O=c.animation.scale;h!==r&&(g((function(){return h})),f((function(){return r}))),a.useEffect((function(){Object(l.c)(b)&&!Object(l.b)(b,h)&&(v.setValue(1),o.a.timing(v,{duration:200*O,toValue:0,useNativeDriver:!0}).start())}),[h,b,v,O]);var w=v,j=b?v.interpolate({inputRange:[0,1],outputRange:[1,0]}):1,E=v.interpolate({inputRange:[0,1],outputRange:["-90deg","0deg"]}),P=b?v.interpolate({inputRange:[0,1],outputRange:["0deg","-180deg"]}):"0deg";return a.createElement(s.a,{style:[p.content,{height:n,width:n}]},b?a.createElement(o.a.View,{style:[p.icon,{opacity:w,transform:[{rotate:E}]}]},a.createElement(l.a,{source:b,size:n,color:t})):null,a.createElement(o.a.View,{style:[p.icon,{opacity:j,transform:[{rotate:P}]}]},a.createElement(l.a,{source:h,size:n,color:t})))}));var p=c.a.create({content:{alignItems:"center",justifyContent:"center"},icon:{position:"absolute",top:0,left:0,right:0,bottom:0}})},443:function(e,t,n){"use strict";n.d(t,"a",(function(){return u}));var r,i,a,o,c=n(393),s=n(11),l=null!==(r=null===(i=c.a.NativeUnimoduleProxy)||void 0===i||null===(a=i.modulesConstants)||void 0===a||null===(o=a.ExponentConstants)||void 0===o?void 0:o.statusBarHeight)&&void 0!==r?r:0,u=s.a.select({android:l,ios:s.a.Version<11?l:0})},446:function(e,t,n){"use strict";var r=n(33),i=n.n(r),a=n(0),o=n(4),c=n(5),s=n(195),l=n(193),u=n(119),p=n(32),d=n(38);function h(e){var t=e.icon,n=e.title,r=e.disabled,o=e.onPress,h=e.style,y=e.contentStyle,m=e.testID,b=e.titleStyle,g=e.accessibilityLabel,v=Object(d.b)(),O=i()(v.dark?p.h:p.a).alpha(.32).rgb().string(),w=r?O:i()(v.colors.text).alpha(.87).rgb().string(),j=r?O:i()(v.colors.text).alpha(.54).rgb().string();return a.createElement(l.a,{style:[f.container,h],onPress:o,disabled:r,testID:m,accessibilityLabel:g,accessibilityRole:"menuitem",accessibilityState:{disabled:r}},a.createElement(c.a,{style:f.row},t?a.createElement(c.a,{style:[f.item,f.icon],pointerEvents:"box-none"},a.createElement(s.a,{source:t,size:24,color:j})):null,a.createElement(c.a,{style:[f.item,f.content,t?f.widthWithIcon:null,y],pointerEvents:"none"},a.createElement(u.a,{selectable:!1,numberOfLines:1,style:[f.title,{color:w},b]},n))))}h.displayName="Menu.Item";var f=o.a.create({container:{paddingHorizontal:8,minWidth:112,maxWidth:280,height:48,justifyContent:"center"},row:{flexDirection:"row"},icon:{width:40},title:{fontSize:16},item:{marginHorizontal:8},content:{justifyContent:"center",minWidth:96,maxWidth:264},widthWithIcon:{maxWidth:192}});t.a=h}}]);
//# sourceMappingURL=13.e7b4b824.chunk.js.map