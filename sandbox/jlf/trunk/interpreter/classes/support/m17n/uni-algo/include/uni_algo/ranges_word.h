/* C++ Standard Library wrapper for Unicode Algorithms Implementation.
 * License: Public Domain or MIT - choose whatever you want.
 * See notice at the end of this file. */

#ifndef UNI_ALGO_RANGES_WORD_H_UAIH
#define UNI_ALGO_RANGES_WORD_H_UAIH

#ifdef UNI_ALGO_DISABLE_BREAK_WORD
#error "Break Word module is disabled via define UNI_ALGO_DISABLE_BREAK_WORD"
#endif

#include <string_view>
#include <cassert>

#include "config.h"
#include "version.h"
#include "internal/safe_layer.h"
#include "internal/ranges_core.h"

#include "impl/impl_iter.h"
#include "impl/impl_break_word.h"

namespace una {

namespace ranges {

namespace word {

template<class Range>
class utf8_view : public detail::rng::view_base
{
private:
    template<class Iter, class Sent>
    class utf8
    {
        static_assert(detail::rng::is_iter_bidi_or_better<Iter>::value &&
                      std::is_integral_v<detail::rng::iter_value_t<Iter>>,
                      "word::utf8 view requires bidirectional or better UTF-8 range");

    private:
        utf8_view* parent = nullptr;
        Iter it_begin = Iter{};
        Iter it_pos = Iter{};
        Iter it_next = Iter{};
        detail::type_codept word_prop = 0;
        detail::type_codept next_word_prop = 0;

        detail::impl_break_word_state state{};

        uaiw_constexpr void iter_func_break_word_utf8()
        {
            it_begin = it_pos;

            while (it_next != std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_next = detail::inline_iter_utf8(it_next, std::end(parent->range), &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_utf8(&state, codepoint, &next_word_prop, it_next, std::end(parent->range)))
                    return;
            }

            if (it_next == std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
            }
        }
        uaiw_constexpr void iter_func_break_word_rev_utf8()
        {
            detail::impl_break_word_state_reset(&state);
            it_pos = it_begin;

            while (it_begin != std::begin(parent->range))
            {
                it_next = it_begin;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_begin = detail::inline_iter_rev_utf8(std::begin(parent->range), it_begin, &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_rev_utf8(&state, codepoint, &next_word_prop, std::begin(parent->range), it_begin))
                {
                    it_begin = it_next;
                    break;
                }
            }

            it_next = it_pos;
            detail::impl_break_word_state_reset(&state);
        }

        using is_contiguous = detail::rng::is_range_contiguous<Range>;

    public:
        using iterator_category = std::bidirectional_iterator_tag;
        using value_type        = std::conditional_t<is_contiguous::value,
            std::basic_string_view<detail::rng::iter_value_t<Iter>>, void>;
        using pointer           = void;
        using reference         = value_type;
        using difference_type   = detail::rng::iter_difference_t<Iter>;

        uaiw_constexpr utf8() = default;
        uaiw_constexpr explicit utf8(utf8_view& p, Iter begin, Sent end)
            : parent{std::addressof(p)}, it_begin{begin}, it_pos{begin}, it_next{begin}
        {
            if (begin == end)
                return;

            detail::impl_break_word_state_reset(&state);

            iter_func_break_word_utf8();
        }
        template<class T = reference> typename std::enable_if_t<is_contiguous::value, T>
        uaiw_constexpr operator*() const
        {
            return detail::rng::to_string_view<reference>(parent->range, it_begin, it_pos);
        }
        uaiw_constexpr Iter begin() const noexcept { return it_begin; }
        uaiw_constexpr Iter end() const noexcept { return it_pos; }
        uaiw_constexpr bool is_word()             const noexcept { return detail::impl_break_is_word(word_prop); }
        uaiw_constexpr bool is_word_number()      const noexcept { return detail::impl_break_is_word_number(word_prop); }
        uaiw_constexpr bool is_word_letter()      const noexcept { return detail::impl_break_is_word_letter(word_prop); }
        uaiw_constexpr bool is_word_kana()        const noexcept { return detail::impl_break_is_word_kana(word_prop); }
        uaiw_constexpr bool is_word_ideographic() const noexcept { return detail::impl_break_is_word_ideo(word_prop); }
        uaiw_constexpr bool is_emoji()            const noexcept { return detail::impl_break_is_word_emoji(word_prop); }
        uaiw_constexpr bool is_punctuation()      const noexcept { return detail::impl_break_is_word_punct(word_prop); }
        uaiw_constexpr bool is_segspace()         const noexcept { return detail::impl_break_is_word_space(word_prop); }
        uaiw_constexpr bool is_newline()          const noexcept { return detail::impl_break_is_word_newline(word_prop); }
        uaiw_constexpr utf8& operator++()
        {
            iter_func_break_word_utf8();

            return *this;
        }
        uaiw_constexpr utf8 operator++(int)
        {
            utf8 tmp = *this;
            operator++();
            return tmp;
        }
        uaiw_constexpr utf8& operator--()
        {
            iter_func_break_word_rev_utf8();

            return *this;
        }
        uaiw_constexpr utf8 operator--(int)
        {
            utf8 tmp = *this;
            operator--();
            return tmp;
        }
        friend uaiw_constexpr bool operator==(const utf8& x, const utf8& y) { return (x.it_begin == y.it_begin); }
        friend uaiw_constexpr bool operator!=(const utf8& x, const utf8& y) { return (x.it_begin != y.it_begin); }
    private:
        static uaiw_constexpr bool friend_compare_sentinel(const utf8& x) { return x.it_begin == std::end(x.parent->range); }
    public:
        friend uaiw_constexpr bool operator==(const utf8& x, una::sentinel_t) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(const utf8& x, una::sentinel_t) { return !friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator==(una::sentinel_t, const utf8& x) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(una::sentinel_t, const utf8& x) { return !friend_compare_sentinel(x); }
    };

    using iter_t = detail::rng::iterator_t<Range>;
    using sent_t = detail::rng::sentinel_t<Range>;

    Range range = Range{};
    utf8<iter_t, sent_t> cached_begin_value;
    bool cached_begin = false;

public:
    uaiw_constexpr utf8_view() = default;
    uaiw_constexpr explicit utf8_view(Range r) : range{std::move(r)} {}
    //uaiw_constexpr Range base() const & { return range; }
    //uaiw_constexpr Range base() && { return std::move(range); }
    uaiw_constexpr auto begin()
    {
        if (cached_begin)
            return cached_begin_value;

        cached_begin_value = utf8<iter_t, sent_t>{*this, std::begin(range), std::end(range)};
        cached_begin = true;

        return cached_begin_value;
    }
    uaiw_constexpr auto end()
    {
        return utf8<iter_t, sent_t>{*this, std::end(range), std::end(range)};
    }
    //uaiw_constexpr bool empty() { return begin() == end(); }
    //explicit uaiw_constexpr operator bool() { return !empty(); }
};

template<class Range>
class utf16_view : public detail::rng::view_base
{
private:
    template<class Iter, class Sent>
    class utf16
    {
        static_assert(detail::rng::is_iter_bidi_or_better<Iter>::value &&
                      std::is_integral_v<detail::rng::iter_value_t<Iter>> &&
                      sizeof(detail::rng::iter_value_t<Iter>) >= sizeof(char16_t),
                      "word::utf16 view requires bidirectional or better UTF-16 range");

    private:
        utf16_view* parent = nullptr;
        Iter it_begin = Iter{};
        Iter it_pos = Iter{};
        Iter it_next = Iter{};
        detail::type_codept word_prop = 0;
        detail::type_codept next_word_prop = 0;

        detail::impl_break_word_state state{};

        uaiw_constexpr void iter_func_break_word_utf16()
        {
            it_begin = it_pos;

            while (it_next != std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_next = detail::inline_iter_utf16(it_next, std::end(parent->range), &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_utf16(&state, codepoint, &next_word_prop, it_next, std::end(parent->range)))
                    return;
            }

            if (it_next == std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
            }
        }
        uaiw_constexpr void iter_func_break_word_rev_utf16()
        {
            detail::impl_break_word_state_reset(&state);
            it_pos = it_begin;

            while (it_begin != std::begin(parent->range))
            {
                it_next = it_begin;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_begin = detail::inline_iter_rev_utf16(std::begin(parent->range), it_begin, &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_rev_utf16(&state, codepoint, &next_word_prop, std::begin(parent->range), it_begin))
                {
                    it_begin = it_next;
                    break;
                }
            }

            it_next = it_pos;
            detail::impl_break_word_state_reset(&state);
        }

        using is_contiguous = detail::rng::is_range_contiguous<Range>;

    public:
        using iterator_category = std::bidirectional_iterator_tag;
        using value_type        = std::conditional_t<is_contiguous::value,
            std::basic_string_view<detail::rng::iter_value_t<Iter>>, void>;
        using pointer           = void;
        using reference         = value_type;
        using difference_type   = detail::rng::iter_difference_t<Iter>;

        uaiw_constexpr utf16() = default;
        uaiw_constexpr explicit utf16(utf16_view& p, Iter begin, Sent end)
            : parent{std::addressof(p)}, it_begin{begin}, it_pos{begin}, it_next{begin}
        {
            if (begin == end)
                return;

            detail::impl_break_word_state_reset(&state);

            iter_func_break_word_utf16();
        }
        template<class T = reference> typename std::enable_if_t<is_contiguous::value, T>
        uaiw_constexpr operator*() const
        {
            return detail::rng::to_string_view<reference>(parent->range, it_begin, it_pos);
        }
        uaiw_constexpr Iter begin() const noexcept { return it_begin; }
        uaiw_constexpr Iter end() const noexcept { return it_pos; }
        uaiw_constexpr bool is_word()             const noexcept { return detail::impl_break_is_word(word_prop); }
        uaiw_constexpr bool is_word_number()      const noexcept { return detail::impl_break_is_word_number(word_prop); }
        uaiw_constexpr bool is_word_letter()      const noexcept { return detail::impl_break_is_word_letter(word_prop); }
        uaiw_constexpr bool is_word_kana()        const noexcept { return detail::impl_break_is_word_kana(word_prop); }
        uaiw_constexpr bool is_word_ideographic() const noexcept { return detail::impl_break_is_word_ideo(word_prop); }
        uaiw_constexpr bool is_emoji()            const noexcept { return detail::impl_break_is_word_emoji(word_prop); }
        uaiw_constexpr bool is_punctuation()      const noexcept { return detail::impl_break_is_word_punct(word_prop); }
        uaiw_constexpr bool is_segspace()         const noexcept { return detail::impl_break_is_word_space(word_prop); }
        uaiw_constexpr bool is_newline()          const noexcept { return detail::impl_break_is_word_newline(word_prop); }
        uaiw_constexpr utf16& operator++()
        {
            iter_func_break_word_utf16();

            return *this;
        }
        uaiw_constexpr utf16 operator++(int)
        {
            utf16 tmp = *this;
            operator++();
            return tmp;
        }
        uaiw_constexpr utf16& operator--()
        {
            iter_func_break_word_rev_utf16();

            return *this;
        }
        uaiw_constexpr utf16 operator--(int)
        {
            utf16 tmp = *this;
            operator--();
            return tmp;
        }
        friend uaiw_constexpr bool operator==(const utf16& x, const utf16& y) { return (x.it_begin == y.it_begin); }
        friend uaiw_constexpr bool operator!=(const utf16& x, const utf16& y) { return (x.it_begin != y.it_begin); }
    private:
        static uaiw_constexpr bool friend_compare_sentinel(const utf16& x) { return x.it_begin == std::end(x.parent->range); }
    public:
        friend uaiw_constexpr bool operator==(const utf16& x, una::sentinel_t) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(const utf16& x, una::sentinel_t) { return !friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator==(una::sentinel_t, const utf16& x) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(una::sentinel_t, const utf16& x) { return !friend_compare_sentinel(x); }
    };

    using iter_t = detail::rng::iterator_t<Range>;
    using sent_t = detail::rng::sentinel_t<Range>;

    Range range = Range{};
    utf16<iter_t, sent_t> cached_begin_value;
    bool cached_begin = false;

public:
    uaiw_constexpr utf16_view() = default;
    uaiw_constexpr explicit utf16_view(Range r) : range{std::move(r)} {}
    //uaiw_constexpr Range base() const & { return range; }
    //uaiw_constexpr Range base() && { return std::move(range); }
    uaiw_constexpr auto begin()
    {
        if (cached_begin)
            return cached_begin_value;

        cached_begin_value = utf16<iter_t, sent_t>{*this, std::begin(range), std::end(range)};
        cached_begin = true;

        return cached_begin_value;
    }
    uaiw_constexpr auto end()
    {
        return utf16<iter_t, sent_t>{*this, std::end(range), std::end(range)};
    }
    //uaiw_constexpr bool empty() { return begin() == end(); }
    //explicit uaiw_constexpr operator bool() { return !empty(); }
};

} // namespace word

namespace word_only {

template<class Range>
class utf8_view : public detail::rng::view_base
{
private:
    template<class Iter, class Sent>
    class utf8
    {
        static_assert(detail::rng::is_iter_bidi_or_better<Iter>::value &&
                      std::is_integral_v<detail::rng::iter_value_t<Iter>>,
                      "word_only::utf8 view requires bidirectional or better UTF-8 range");

    private:
        utf8_view* parent = nullptr;
        Iter it_begin = Iter{};
        Iter it_pos = Iter{};
        Iter it_next = Iter{};
        detail::type_codept word_prop = 0;
        detail::type_codept next_word_prop = 0;

        detail::impl_break_word_state state{};

        uaiw_constexpr void iter_func_break_word_only_utf8()
        {
            it_begin = it_pos;

            while (it_next != std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_next = detail::inline_iter_utf8(it_next, std::end(parent->range), &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_utf8(&state, codepoint, &next_word_prop, it_next, std::end(parent->range)))
                {
                    if (detail::impl_break_is_word(word_prop))
                        return;

                    it_begin = it_pos;
                    continue;
                }
            }

            if (it_next == std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                if (!detail::impl_break_is_word(word_prop))
                    it_begin = it_next;
            }
        }

        uaiw_constexpr void iter_func_break_word_only_rev_utf8()
        {
            detail::impl_break_word_state_reset(&state);
            it_pos = it_begin;

            while (it_begin != std::begin(parent->range))
            {
                it_next = it_begin;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_begin = detail::inline_iter_rev_utf8(std::begin(parent->range), it_begin, &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_rev_utf8(&state, codepoint, &next_word_prop, std::begin(parent->range), it_begin))
                {
                    if (detail::impl_break_is_word(word_prop))
                    {
                        it_begin = it_next;
                        break;
                    }
                    it_pos = it_next;
                }
            }

            it_next = it_pos;
            detail::impl_break_word_state_reset(&state);
        }

        using is_contiguous = detail::rng::is_range_contiguous<Range>;

    public:
        using iterator_category = std::bidirectional_iterator_tag;
        using value_type        = std::conditional_t<is_contiguous::value,
            std::basic_string_view<detail::rng::iter_value_t<Iter>>, void>;
        using pointer           = void;
        using reference         = value_type;
        using difference_type   = detail::rng::iter_difference_t<Iter>;

        uaiw_constexpr utf8() = default;
        uaiw_constexpr explicit utf8(utf8_view& p, Iter begin, Sent end)
            : parent{std::addressof(p)}, it_begin{begin}, it_pos{begin}, it_next{begin}
        {
            if (begin == end)
                return;

            detail::impl_break_word_state_reset(&state);

            iter_func_break_word_only_utf8();
        }
        template<class T = reference> typename std::enable_if_t<is_contiguous::value, T>
        uaiw_constexpr operator*() const
        {
            return detail::rng::to_string_view<reference>(parent->range, it_begin, it_pos);
        }
        uaiw_constexpr Iter begin() const noexcept { return it_begin; }
        uaiw_constexpr Iter end() const noexcept { return it_pos; }
        uaiw_constexpr utf8& operator++()
        {
            iter_func_break_word_only_utf8();

            return *this;
        }
        uaiw_constexpr utf8 operator++(int)
        {
            utf8 tmp = *this;
            operator++();
            return tmp;
        }
        uaiw_constexpr utf8& operator--()
        {
            iter_func_break_word_only_rev_utf8();

            return *this;
        }
        uaiw_constexpr utf8 operator--(int)
        {
            utf8 tmp = *this;
            operator--();
            return tmp;
        }
        friend uaiw_constexpr bool operator==(const utf8& x, const utf8& y) { return (x.it_begin == y.it_begin); }
        friend uaiw_constexpr bool operator!=(const utf8& x, const utf8& y) { return (x.it_begin != y.it_begin); }
    private:
        static uaiw_constexpr bool friend_compare_sentinel(const utf8& x) { return x.it_begin == std::end(x.parent->range); }
    public:
        friend uaiw_constexpr bool operator==(const utf8& x, una::sentinel_t) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(const utf8& x, una::sentinel_t) { return !friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator==(una::sentinel_t, const utf8& x) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(una::sentinel_t, const utf8& x) { return !friend_compare_sentinel(x); }
    };

    using iter_t = detail::rng::iterator_t<Range>;
    using sent_t = detail::rng::sentinel_t<Range>;

    Range range = Range{};
    utf8<iter_t, sent_t> cached_begin_value;
    bool cached_begin = false;

public:
    uaiw_constexpr utf8_view() = default;
    uaiw_constexpr explicit utf8_view(Range r) : range{std::move(r)} {}
    //uaiw_constexpr Range base() const & { return range; }
    //uaiw_constexpr Range base() && { return std::move(range); }
    uaiw_constexpr auto begin()
    {
        if (cached_begin)
            return cached_begin_value;

        cached_begin_value = utf8<iter_t, sent_t>{*this, std::begin(range), std::end(range)};
        cached_begin = true;

        return cached_begin_value;
    }
    uaiw_constexpr auto end()
    {
        return utf8<iter_t, sent_t>{*this, std::end(range), std::end(range)};
    }
    //uaiw_constexpr bool empty() { return begin() == end(); }
    //explicit uaiw_constexpr operator bool() { return !empty(); }
};

template<class Range>
class utf16_view : public detail::rng::view_base
{
private:
    template<class Iter, class Sent>
    class utf16
    {
        static_assert(detail::rng::is_iter_bidi_or_better<Iter>::value &&
                      std::is_integral_v<detail::rng::iter_value_t<Iter>> &&
                      sizeof(detail::rng::iter_value_t<Iter>) >= sizeof(char16_t),
                      "word_only::utf16 view requires bidirectional or better UTF-16 range");

    private:
        utf16_view* parent = nullptr;
        Iter it_begin = Iter{};
        Iter it_pos = Iter{};
        Iter it_next = Iter{};
        detail::type_codept word_prop = 0;
        detail::type_codept next_word_prop = 0;

        detail::impl_break_word_state state{};

        uaiw_constexpr void iter_func_break_word_only_utf16()
        {
            it_begin = it_pos;

            while (it_next != std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_next = detail::inline_iter_utf16(it_next, std::end(parent->range), &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_utf16(&state, codepoint, &next_word_prop, it_next, std::end(parent->range)))
                {
                    if (detail::impl_break_is_word(word_prop))
                        return;

                    it_begin = it_pos;
                    continue;
                }
            }

            if (it_next == std::end(parent->range))
            {
                it_pos = it_next;
                word_prop = next_word_prop;
                if (!detail::impl_break_is_word(word_prop))
                    it_begin = it_next;
            }
        }

        uaiw_constexpr void iter_func_break_word_only_rev_utf16()
        {
            detail::impl_break_word_state_reset(&state);
            it_pos = it_begin;

            while (it_begin != std::begin(parent->range))
            {
                it_next = it_begin;
                word_prop = next_word_prop;
                detail::type_codept codepoint = 0;
                it_begin = detail::inline_iter_rev_utf16(std::begin(parent->range), it_begin, &codepoint, detail::impl_iter_replacement);
                if (detail::inline_break_word_rev_utf16(&state, codepoint, &next_word_prop, std::begin(parent->range), it_begin))
                {
                    if (detail::impl_break_is_word(word_prop))
                    {
                        it_begin = it_next;
                        break;
                    }
                    it_pos = it_next;
                }
            }

            it_next = it_pos;
            detail::impl_break_word_state_reset(&state);
        }

        using is_contiguous = detail::rng::is_range_contiguous<Range>;

    public:
        using iterator_category = std::bidirectional_iterator_tag;
        using value_type        = std::conditional_t<is_contiguous::value,
            std::basic_string_view<detail::rng::iter_value_t<Iter>>, void>;
        using pointer           = void;
        using reference         = value_type;
        using difference_type   = detail::rng::iter_difference_t<Iter>;

        uaiw_constexpr utf16() = default;
        uaiw_constexpr explicit utf16(utf16_view& p, Iter begin, Sent end)
            : parent{std::addressof(p)}, it_begin{begin}, it_pos{begin}, it_next{begin}
        {
            if (begin == end)
                return;

            detail::impl_break_word_state_reset(&state);

            iter_func_break_word_only_utf16();
        }
        template<class T = reference> typename std::enable_if_t<is_contiguous::value, T>
        uaiw_constexpr operator*() const
        {
            return detail::rng::to_string_view<reference>(parent->range, it_begin, it_pos);
        }
        uaiw_constexpr Iter begin() const noexcept { return it_begin; }
        uaiw_constexpr Iter end() const noexcept { return it_pos; }
        uaiw_constexpr utf16& operator++()
        {
            iter_func_break_word_only_utf16();

            return *this;
        }
        uaiw_constexpr utf16 operator++(int)
        {
            utf16 tmp = *this;
            operator++();
            return tmp;
        }
        uaiw_constexpr utf16& operator--()
        {
            iter_func_break_word_only_rev_utf16();

            return *this;
        }
        uaiw_constexpr utf16 operator--(int)
        {
            utf16 tmp = *this;
            operator--();
            return tmp;
        }
        friend uaiw_constexpr bool operator==(const utf16& x, const utf16& y) { return (x.it_begin == y.it_begin); }
        friend uaiw_constexpr bool operator!=(const utf16& x, const utf16& y) { return (x.it_begin != y.it_begin); }
    private:
        static uaiw_constexpr bool friend_compare_sentinel(const utf16& x) { return x.it_begin == std::end(x.parent->range); }
    public:
        friend uaiw_constexpr bool operator==(const utf16& x, una::sentinel_t) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(const utf16& x, una::sentinel_t) { return !friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator==(una::sentinel_t, const utf16& x) { return friend_compare_sentinel(x); }
        friend uaiw_constexpr bool operator!=(una::sentinel_t, const utf16& x) { return !friend_compare_sentinel(x); }
    };

    using iter_t = detail::rng::iterator_t<Range>;
    using sent_t = detail::rng::sentinel_t<Range>;

    Range range = Range{};
    utf16<iter_t, sent_t> cached_begin_value;
    bool cached_begin = false;

public:
    uaiw_constexpr utf16_view() = default;
    uaiw_constexpr explicit utf16_view(Range r) : range{std::move(r)} {}
    //uaiw_constexpr Range base() const & { return range; }
    //uaiw_constexpr Range base() && { return std::move(range); }
    uaiw_constexpr auto begin()
    {
        if (cached_begin)
            return cached_begin_value;

        cached_begin_value = utf16<iter_t, sent_t>{*this, std::begin(range), std::end(range)};
        cached_begin = true;

        return cached_begin_value;
    }
    uaiw_constexpr auto end()
    {
        return utf16<iter_t, sent_t>{*this, std::end(range), std::end(range)};
    }
    //uaiw_constexpr bool empty() { return begin() == end(); }
    //explicit uaiw_constexpr operator bool() { return !empty(); }
};

} // namespace word_only

namespace word {
template<class Range>
utf8_view(Range&&) -> utf8_view<views::all_t<Range>>;
template<class Range>
utf16_view(Range&&) -> utf16_view<views::all_t<Range>>;
}
namespace word_only {
template<class Range>
utf8_view(Range&&) -> utf8_view<views::all_t<Range>>;
template<class Range>
utf16_view(Range&&) -> utf16_view<views::all_t<Range>>;
}

} // namespace ranges

namespace detail::rng {

/* WORD_UTF8_VIEW */

struct adaptor_word_utf8
{
    template<class R>
    uaiw_constexpr auto operator()(R&& r) const
    { return ranges::word::utf8_view{std::forward<R>(r)}; }
};
template<class R>
uaiw_constexpr auto operator|(R&& r, const adaptor_word_utf8& a) { return a(std::forward<R>(r)); }

/* WORD_UTF16_VIEW */

struct adaptor_word_utf16
{
    template<class R>
    uaiw_constexpr auto operator()(R&& r) const
    { return ranges::word::utf16_view{std::forward<R>(r)}; }
};
template<class R>
uaiw_constexpr auto operator|(R&& r, const adaptor_word_utf16& a) { return a(std::forward<R>(r)); }

/* WORD_ONLY_UTF8_VIEW */

struct adaptor_word_only_utf8
{
    template<class R>
    uaiw_constexpr auto operator()(R&& r) const
    { return ranges::word_only::utf8_view{std::forward<R>(r)}; }
};
template<class R>
uaiw_constexpr auto operator|(R&& r, const adaptor_word_only_utf8& a) { return a(std::forward<R>(r)); }

/* WORD_ONLY_UTF16_VIEW */

struct adaptor_word_only_utf16
{
    template<class R>
    uaiw_constexpr auto operator()(R&& r) const
    { return ranges::word_only::utf16_view{std::forward<R>(r)}; }
};
template<class R>
uaiw_constexpr auto operator|(R&& r, const adaptor_word_only_utf16& a) { return a(std::forward<R>(r)); }

} // namespace detail::rng

namespace ranges::views {

namespace word {
inline constexpr detail::rng::adaptor_word_utf8 utf8;
inline constexpr detail::rng::adaptor_word_utf16 utf16;
}
namespace word_only {
inline constexpr detail::rng::adaptor_word_only_utf8 utf8;
inline constexpr detail::rng::adaptor_word_only_utf16 utf16;
}

} // namespace ranges::views

namespace views = ranges::views;

} // namespace una

#endif // UNI_ALGO_RANGES_WORD_H_UAIH

/* Public Domain License
 *
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
 * software, either in source code form or as a compiled binary, for any purpose,
 * commercial or non-commercial, and by any means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors of this
 * software dedicate any and all copyright interest in the software to the public
 * domain. We make this dedication for the benefit of the public at large and to
 * the detriment of our heirs and successors. We intend this dedication to be an
 * overt act of relinquishment in perpetuity of all present and future rights to
 * this software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
