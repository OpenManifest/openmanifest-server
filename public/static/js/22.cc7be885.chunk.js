(this.webpackJsonp=this.webpackJsonp||[]).push([[22],{638:function(n,e,t){"use strict";t.d(e,"a",(function(){return i}));var r=t(62),a=t(45);function i(n,e){Object(a.a)(2,arguments);var t=Object(r.a)(n),i=Object(r.a)(e);return t.getTime()-i.getTime()}},780:function(n,e,t){"use strict";t.r(e),t.d(e,"default",(function(){return V}));var r,a=t(12),i=t.n(a),o=t(36),c=t.n(o),s=t(56),u=t(47),f=t(0),l=t(224),d=t(1),b=t(388),m=t(37),O=t(7),g=t(158),p=t(4),h=t.n(p);function v(n,e){var t=Object.keys(n);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(n);e&&(r=r.filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable}))),t.push.apply(t,r)}return t}function j(n){for(var e=1;e<arguments.length;e++){var t=null!=arguments[e]?arguments[e]:{};e%2?v(Object(t),!0).forEach((function(e){h()(n,e,t[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(n,Object.getOwnPropertyDescriptors(t)):v(Object(t)).forEach((function(e){Object.defineProperty(n,e,Object.getOwnPropertyDescriptor(t,e))}))}return n}var y=Object(m.a)(r||(r=c()(["\n  query QueryNotifications($dropzoneId: Int!) {\n    dropzone(id: $dropzoneId) {\n      id\n\n      currentUser {\n        id\n        \n        notifications {\n          edges {\n            node {\n              id\n              message\n              notificationType\n              createdAt\n\n              resource {\n                ...on Load {\n                  id\n                  loadNumber\n                  dispatchAt\n                }\n                ...on Transaction {\n                  id\n                  amount\n                  message\n                  status\n                }\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n"])));var D=t(330),M=t(29),w=t.n(M),E=t(24),S=t(241),T=t(375),I=t(62),N=t(45);function X(n,e){Object(N.a)(2,arguments);var t=Object(I.a)(n),r=Object(I.a)(e),a=t.getTime()-r.getTime();return a<0?-1:a>0?1:a}function x(n,e){Object(N.a)(2,arguments);var t=Object(I.a)(n),r=Object(I.a)(e),a=t.getFullYear()-r.getFullYear(),i=t.getMonth()-r.getMonth();return 12*a+i}function P(n){Object(N.a)(1,arguments);var e=Object(I.a)(n);return e.setHours(23,59,59,999),e}function A(n){Object(N.a)(1,arguments);var e=Object(I.a)(n),t=e.getMonth();return e.setFullYear(e.getFullYear(),t+1,0),e.setHours(23,59,59,999),e}function F(n){Object(N.a)(1,arguments);var e=Object(I.a)(n);return P(e).getTime()===A(e).getTime()}function $(n,e){Object(N.a)(2,arguments);var t,r=Object(I.a)(n),a=Object(I.a)(e),i=X(r,a),o=Math.abs(x(r,a));if(o<1)t=0;else{1===r.getMonth()&&r.getDate()>27&&r.setDate(30),r.setMonth(r.getMonth()-i*o);var c=X(r,a)===-i;F(Object(I.a)(n))&&1===o&&1===X(n,a)&&(c=!1),t=i*(o-Number(c))}return 0===t?0:t}var k=t(638);function z(n,e){Object(N.a)(2,arguments);var t=Object(k.a)(n,e)/1e3;return t>0?Math.floor(t):Math.ceil(t)}var Y=t(392);function B(n){return function(n,e){if(null==n)throw new TypeError("assign requires that input parameter not be null or undefined");for(var t in e=e||{})e.hasOwnProperty(t)&&(n[t]=e[t]);return n}({},n)}var H,R=t(385);function q(n,e){var t=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{};Object(N.a)(2,arguments);var r=t.locale||Y.a;if(!r.formatDistance)throw new RangeError("locale must contain formatDistance property");var a=X(n,e);if(isNaN(a))throw new RangeError("Invalid time value");var i,o,c=B(t);c.addSuffix=Boolean(t.addSuffix),c.comparison=a,a>0?(i=Object(I.a)(e),o=Object(I.a)(n)):(i=Object(I.a)(n),o=Object(I.a)(e));var s,u=z(o,i),f=(Object(R.a)(o)-Object(R.a)(i))/1e3,l=Math.round((u-f)/60);if(l<2)return t.includeSeconds?u<5?r.formatDistance("lessThanXSeconds",5,c):u<10?r.formatDistance("lessThanXSeconds",10,c):u<20?r.formatDistance("lessThanXSeconds",20,c):u<40?r.formatDistance("halfAMinute",null,c):u<60?r.formatDistance("lessThanXMinutes",1,c):r.formatDistance("xMinutes",1,c):0===l?r.formatDistance("lessThanXMinutes",1,c):r.formatDistance("xMinutes",l,c);if(l<45)return r.formatDistance("xMinutes",l,c);if(l<90)return r.formatDistance("aboutXHours",1,c);if(l<1440){var d=Math.round(l/60);return r.formatDistance("aboutXHours",d,c)}if(l<2520)return r.formatDistance("xDays",1,c);if(l<43200){var b=Math.round(l/1440);return r.formatDistance("xDays",b,c)}if(l<86400)return s=Math.round(l/43200),r.formatDistance("aboutXMonths",s,c);if((s=$(o,i))<12){var m=Math.round(l/43200);return r.formatDistance("xMonths",m,c)}var O=s%12,g=Math.floor(s/12);return O<3?r.formatDistance("aboutXYears",g,c):O<9?r.formatDistance("overXYears",g,c):r.formatDistance("almostXYears",g+1,c)}function C(n,e){return Object(N.a)(1,arguments),q(n,Date.now(),e)}var J,L=Object(m.a)(H||(H=c()(["\n  mutation MarkAsSeen(\n    $id: Int,\n  ){\n    updateNotification(input: {\n      id: $id\n      attributes: {\n        isSeen: true,\n      }\n    }) {\n      notification {\n        id\n        isSeen\n        message\n        notificationType\n        receivedBy {\n          notifications {\n            edges {\n              node {\n                id\n                message\n                isSeen\n                notificationType\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n"])));function Q(n){var e=n.notification,t=Object(u.useMutation)(L),r=i()(t,2);r[0],r[1];return f.createElement(f.Fragment,null,f.createElement(E.b.Item,{title:"Manifest",description:e.message,style:{width:"100%"},left:function(n){return f.createElement(E.b.Icon,w()({},n,{icon:"airplane"}))},right:function(){return f.createElement(S.a,null,C(1e3*e.createdAt))}}),f.createElement(T.a,{style:{width:"100%"}}))}var U,_=Object(m.a)(J||(J=c()(["\n  mutation MarkAsSeen(\n    $id: Int,\n  ){\n    updateNotification(input: {\n      id: $id\n      attributes: {\n        isSeen: true,\n      }\n    }) {\n      notification {\n        id\n        isSeen\n        message\n        notificationType\n        receivedBy {\n          notifications {\n            edges {\n              node {\n                id\n                message\n                isSeen\n                notificationType\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n"])));function G(n){var e=n.notification,t=Object(u.useMutation)(_),r=i()(t,2);r[0],r[1];return f.createElement(f.Fragment,null,f.createElement(E.b.Item,{title:"Load #"+e.resource.loadNumber+" boarding call",description:e.message,style:{width:"100%"},left:function(n){return f.createElement(E.b.Icon,w()({},n,{icon:"airplane-takeoff"}))},right:function(){return f.createElement(S.a,null,C(1e3*e.createdAt))}}),f.createElement(T.a,{style:{width:"100%"}}))}var K=Object(m.a)(U||(U=c()(["\n  mutation MarkAsSeen(\n    $id: Int,\n  ){\n    updateNotification(input: {\n      id: $id\n      attributes: {\n        isSeen: true,\n      }\n    }) {\n      notification {\n        id\n        isSeen\n        message\n        notificationType\n        receivedBy {\n          notifications {\n            edges {\n              node {\n                id\n                message\n                isSeen\n                notificationType\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n"])));function V(){var n,e,t=Object(O.c)((function(n){return n.global})),r=function(){var n,e,t=Object(O.c)((function(n){return n.global.currentDropzoneId})),r=Object(u.useQuery)(y,{variables:{dropzoneId:t},pollInterval:3e4});return j(j({},r),{},{notifications:null==r||null==(n=r.data)||null==(e=n.dropzone)?void 0:e.currentUser.notifications})}(),a=r.notifications,o=r.loading,c=r.refetch,d=Object(s.useIsFocused)();f.useEffect((function(){d&&c()}),[d]);var m=Object(u.useMutation)(K),p=i()(m,2);p[0],p[1];return f.createElement(f.Fragment,null,o&&f.createElement(b.a,{color:t.theme.colors.accent,indeterminate:!0,visible:o}),f.createElement(g.a,{contentContainerStyle:W.content,refreshControl:f.createElement(l.a,{refreshing:o,onRefresh:function(){return c()}})},null!=a&&null!=(n=a.edges)&&n.length?null==a||null==(e=a.edges)?void 0:e.map((function(n){switch(n.node.notificationType){case"boarding_call":return f.createElement(G,{notification:n.node});case"user_manifested":return f.createElement(Q,{notification:n.node});default:return null}})):f.createElement(D.a,{title:"No notifications",subtitle:"Notifications will show up here"})))}var W=d.a.create({container:{flex:1},content:{flexGrow:1,paddingBottom:56,paddingHorizontal:0},divider:{height:1,width:"100%"}})}}]);
//# sourceMappingURL=22.cc7be885.chunk.js.map