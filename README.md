# 拯救 Windows 笔记本键盘



>  前情提要：
>
> 通过 QMK（[k6pro](https://github.com/kurikomoe/qmk_firmware/tree/bluetooth_playground/keyboards/keychron/k6_pro)）实现了一套自己觉得很舒服的 65% 配列的快捷键系统。
>
> 其中最重要的是通过 RFn + wasd, zxc, fv 实现了对鼠标操作的模拟

显然，QMK 配置对于 windows 笔记本的内置键盘和某些写的很烂且不开源的固件（GMK67-s）是没啥用的。

为此只能使用键盘映射方法补齐对应的功能。



> [!note]
>
> 对于 macOS 来说，可以使用 Karabiner-Elements 实现。
>
> 最好的是，Bytedance 企业策略竟然允许装这玩意。



对于 Windows 来说，目前目前可以使用 `AutoHotkey` 和 `kanata` 实现，这里我使用了 `kanata`

配置如下（以 repo 最新的 `kanata.kbd` 为基准）

```kanata
(defcfg
  process-unmapped-keys yes
)

(defsrc
  w  a  s  d  f  v
  h  j  k  l  ;  '
  z  x  c
  ralt
  ;; 新增：拦截来自键盘硬件层(VIA)的虚拟键
  f13 f14 f15 f16
)

(defalias
  nav_mod (tap-hold 200 200 ralt (layer-while-held navigation))

  ;; 滚轮保持不变
  mwd (mwheel-down 50 120)
  mwu (mwheel-up   50 120)

  ;; 高分屏鼠标参数调整：
  ;; 10  : 间隔时间 (保持 100Hz 刷新率)
  ;; 800 : 加速时间 (ms)，0.8秒内达到最快速度 (比之前更快进入高速状态)
  ;; 2   : 最小距离 (px)，起步稍微快一点点，避免高分屏上感觉“动不了”
  ;; 75  : 最大距离 (px)，大幅提升极速 (之前是 20)，方便跨越 4K 屏幕
  ms_up    (movemouse-accel-up    10 1000 2 60)
  ms_left  (movemouse-accel-left  10 1000 2 60)
  ms_down  (movemouse-accel-down  10 1000 2 60)
  ms_right (movemouse-accel-right 10 1000 2 60)
)

(deflayer default
  w  a  s  d  f  v
  h  j  k  l  ;  '
  z  x  c
  @nav_mod
  ;; 修正 gmk67-s 的 bug
  @ms_left  ;; 映射 F13 (a)
  @ms_down  ;; 映射 F14 (s)
  @ms_right ;; 映射 F15 (d)
  @ms_up ;; 映射 F16 (w)
)

(deflayer navigation
  @ms_up  @ms_left  @ms_down  @ms_right  @mwd  @mwu
  left    down      up        right      home  end
  mlft    mmid      mrgt
  _
  f13 f14 f15 f16
)

```



## GMK67-s bug

对于 GMK67 这里有一个问题，GMK67 本身是支持 via 做按键映射的，但是他的 mouse key 实现有 bug，在长按 mouse key 的情况下，鼠标光标只会移动一次，不会连续移动。

为了修正这个 bug ，这里将 wasd 映射为 F13-F16，之后在 `kanata` 的配置文件里面重新映射为鼠标操作。



## 安装说明

> [!caution]
>
> 由于 kanata 必须保持窗口运行。
>
> 为了实现开机自启和后台运行，`install.ps1`使用了任务计划 + vbs 脚本实现无窗口后台运行 kanata。

以管理员模式运行 `install.ps1`，脚本会自动根据目录生成 `start_hidden.vbs` 文件，并配置开机自启的任务计划。



## 版本说明

repo 里面的 katana 为版本 1.10.1