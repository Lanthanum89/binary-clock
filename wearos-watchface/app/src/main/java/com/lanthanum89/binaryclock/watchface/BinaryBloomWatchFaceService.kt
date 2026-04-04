package com.lanthanum89.binaryclock.watchface

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.Icon
import android.view.SurfaceHolder
import androidx.wear.watchface.CanvasType
import androidx.wear.watchface.ComplicationSlotsManager
import androidx.wear.watchface.Renderer
import androidx.wear.watchface.WatchFace
import androidx.wear.watchface.WatchFaceService
import androidx.wear.watchface.WatchFaceType
import androidx.wear.watchface.WatchState
import androidx.wear.watchface.style.CurrentUserStyleRepository
import androidx.wear.watchface.style.ListUserStyleSetting
import androidx.wear.watchface.style.UserStyleSetting
import androidx.wear.watchface.style.UserStyleSchema
import androidx.wear.watchface.style.WatchFaceLayer
import java.time.ZonedDateTime
import kotlin.math.min

class BinaryBloomWatchFaceService : WatchFaceService() {

    companion object {
        private val TIME_FORMAT_SETTING_ID = UserStyleSetting.Id("time_format")
        private val TIME_FORMAT_24H_OPTION_ID = UserStyleSetting.Option.Id("24h")
        private val TIME_FORMAT_12H_OPTION_ID = UserStyleSetting.Option.Id("12h")
    }

    override suspend fun createWatchFace(
        surfaceHolder: SurfaceHolder,
        watchState: WatchState,
        complicationSlotsManager: ComplicationSlotsManager,
        currentUserStyleRepository: CurrentUserStyleRepository
    ): WatchFace {
        val timeFormatSetting = createTimeFormatSetting()

        val renderer = BinaryBloomRenderer(
            surfaceHolder = surfaceHolder,
            watchState = watchState,
            currentUserStyleRepository = currentUserStyleRepository,
            timeFormatSetting = timeFormatSetting,
            twentyFourHourOptionId = TIME_FORMAT_24H_OPTION_ID
        )

        return WatchFace(WatchFaceType.DIGITAL, renderer)
    }

    override fun createUserStyleSchema(): UserStyleSchema = UserStyleSchema(
        listOf(createTimeFormatSetting())
    )

    override fun createComplicationSlotsManager(
        currentUserStyleRepository: CurrentUserStyleRepository
    ): ComplicationSlotsManager = ComplicationSlotsManager(emptyList(), currentUserStyleRepository)

    private fun createTimeFormatSetting(): ListUserStyleSetting {
        val icon = Icon.createWithResource(this, R.drawable.ic_watchface_branding)

        return ListUserStyleSetting(
            TIME_FORMAT_SETTING_ID,
            resources,
            R.string.time_format_setting_name,
            R.string.time_format_setting_description,
            icon,
            listOf(
                ListUserStyleSetting.ListOption(
                    TIME_FORMAT_24H_OPTION_ID,
                    resources,
                    R.string.time_format_24h,
                    icon
                ),
                ListUserStyleSetting.ListOption(
                    TIME_FORMAT_12H_OPTION_ID,
                    resources,
                    R.string.time_format_12h,
                    icon
                )
            ),
            listOf(WatchFaceLayer.BASE)
        )
    }
}

private class BinaryBloomRenderer(
    surfaceHolder: SurfaceHolder,
    currentUserStyleRepository: CurrentUserStyleRepository,
    watchState: WatchState,
    private val timeFormatSetting: ListUserStyleSetting,
    private val twentyFourHourOptionId: UserStyleSetting.Option.Id
) : Renderer.CanvasRenderer(
    surfaceHolder,
    currentUserStyleRepository,
    watchState,
    CanvasType.HARDWARE,
    16L,
    false
) {
    private val backgroundPaint = Paint().apply {
        color = 0xFF1B1024.toInt()
        isAntiAlias = true
    }

    private val panelPaint = Paint().apply {
        color = 0x332D1A3B
        isAntiAlias = true
    }

    private val activeDotPaint = Paint().apply {
        color = 0xFFFF9AD8.toInt()
        isAntiAlias = true
    }

    private val inactiveDotPaint = Paint().apply {
        color = 0x4DFFFFFF
        isAntiAlias = true
    }

    private val labelPaint = Paint().apply {
        color = 0xCCF4DFFF.toInt()
        textAlign = Paint.Align.CENTER
        textSize = 16f
        isAntiAlias = true
    }

    private val decimalPaint = Paint().apply {
        color = 0xFFFFFFFF.toInt()
        textAlign = Paint.Align.CENTER
        textSize = 26f
        isFakeBoldText = true
        isAntiAlias = true
    }

    override fun render(canvas: Canvas, bounds: Rect, zonedDateTime: ZonedDateTime) {
        val width = bounds.width().toFloat()
        val height = bounds.height().toFloat()

        canvas.drawRect(bounds, backgroundPaint)

        val padding = width * 0.06f
        val panelRect = RectF(
            padding,
            padding,
            width - padding,
            height - padding
        )
        canvas.drawRoundRect(panelRect, 24f, 24f, panelPaint)

        val is24Hour = currentUserStyleRepository.userStyle[timeFormatSetting]?.id ==
            twentyFourHourOptionId
        val hourValue = if (is24Hour) {
            zonedDateTime.hour
        } else {
            ((zonedDateTime.hour + 11) % 12) + 1
        }

        val units = intArrayOf(
            hourValue,
            zonedDateTime.minute,
            zonedDateTime.second
        )
        val labels = arrayOf("H", "M", "S")

        val columnWidth = panelRect.width() / 3f
        val dotRadius = min(columnWidth, panelRect.height()) * 0.06f
        val rowGap = dotRadius * 2.6f
        val groupGap = dotRadius * 2.2f

        for (i in units.indices) {
            val colCenterX = panelRect.left + columnWidth * i + columnWidth / 2f
            val topY = panelRect.top + dotRadius * 2.6f

            canvas.drawText(labels[i], colCenterX, topY, labelPaint)

            val value = units[i]
            val tens = value / 10
            val ones = value % 10

            val tensX = colCenterX - groupGap
            val onesX = colCenterX + groupGap
            val startY = topY + dotRadius * 2.2f

            drawBinaryDigit(canvas, tens, tensX, startY, dotRadius, rowGap)
            drawBinaryDigit(canvas, ones, onesX, startY, dotRadius, rowGap)

            canvas.drawText(
                value.toString().padStart(2, '0'),
                colCenterX,
                panelRect.bottom - dotRadius * 1.2f,
                decimalPaint
            )
        }
    }

    override fun renderHighlightLayer(
        canvas: Canvas,
        bounds: Rect,
        zonedDateTime: ZonedDateTime
    ) {
        canvas.drawColor(0x33FFFFFF)
    }

    private fun drawBinaryDigit(
        canvas: Canvas,
        digit: Int,
        centerX: Float,
        startY: Float,
        radius: Float,
        rowGap: Float
    ) {
        val bits = digit.toString(2).padStart(4, '0')

        for (index in bits.indices) {
            val y = startY + index * rowGap
            val isActive = bits[index] == '1'
            canvas.drawCircle(
                centerX,
                y,
                radius,
                if (isActive) activeDotPaint else inactiveDotPaint
            )
        }
    }
}
