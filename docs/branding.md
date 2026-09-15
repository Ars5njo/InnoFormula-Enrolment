# Оформление клуба

Логотип в `assets/branding/club-mark.png` адаптирован из изображения, предоставленного владельцем клуба. Сохранены три болида и порядок цветов: зелёный, оранжевый, красный. Файл содержит прозрачный альфа-канал и используется в шапке сайта. Исходное изображение не изменялось.

Обработка: встроенный инструмент image_gen (без CLI).

## Промпт логотипа

```text
Use case: style-transfer / background-extraction. Edit target: the provided InnoFormula club logo, showing three side-view Formula racing cars stacked vertically, pointing right; green top, orange middle, red bottom. Primary request: refine this exact club mark for a dark racing-timing website masthead. Preserve THREE cars, their recognizable open-wheel side profiles, the vertical stack and green-orange-red order. Redraw as clean, confident, slightly simplified monoline outlines with consistent rounded stroke ends, no sketch noise. Use luminous green #54C95C, warm orange #FFA23B, and red #FF493F so the mark is clear on #101113. Make the strokes thick enough to remain legible when the whole mark is displayed around 90 pixels wide. Remove the white background completely: output true transparent alpha PNG, also transparent inside the wheels and between the strokes, not a checkerboard painted into the image. No text, no initials, no frame, no shadow, no glow, no added objects. Tightly frame the three stacked cars with balanced narrow margins (about 4%), wide landscape canvas aspect ratio approximately 3:2, the mark filling nearly all the image. Do not include a website mockup, only the standalone polished logo asset.
```

## Референс интерфейса

[F1, F1 & F3 Brand Concepts, блок 10](https://www.figma.com/design/KPosPC4WRrVZJnkfmmeiHY/F1--F1---F3-Brand-Concepts--Community-?node-id=0-579).

Применены приёмы публично доступного визуального референса: тёмный сине-фиолетовый фон, красные рамки, широкая типографика, линии траектории и компактная таблица тайминга. Это адаптация для лидерборда клуба. Точные токены и исходные ресурсы Figma недоступны коннектору из-за отсутствия прав редактирования. Используются собственный логотип клуба и открытые шрифты с кириллицей.
