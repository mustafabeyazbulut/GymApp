---
name: feedback-turkish-comments-and-commits
description: Kullanıcı tüm kod açıklamalarının, tüm git commit mesajlarının VE kullanıcıya yazılan tüm sohbet yanıtlarının sadece Türkçe olmasını istiyor, hem GymApp'te hem GymAppApi'de. Herhangi bir açıklama, commit mesajı veya sohbet yanıtı yazmadan önce bunu oku.
metadata:
  type: feedback
---

# Kod açıklamaları, commit mesajları VE sohbet yanıtları sadece Türkçe olacak (2026-09-19, aynı gün pekiştirildi)

Kullanıcının ilk talimatı, oturum ortasında (GymAppApi'de çalışırken söylendi, burada da geçerli): "kod açıklamalarını türkçeye çevir her zaman türkçe yazsın commit satırları".

**Aynı gün, daha sert şekilde pekiştirildi, Claude sohbette İngilizce yanıt vermeye devam edince:** "bir daha uyarmayacağım seni bana sadece türkçe açıklama yaz. kod stırına da sadece türkçe açıklama yaz". Kullanıcıya verilen her sohbet yanıtı, hangi repo/oturumda olursa olsun, bundan sonra sadece Türkçe olacak - istisnasız. Kullanıcı ayrıca, bu kuralın kaydedildiği hafıza dosyasının kendisinin İngilizce yazılmış olmasını da eleştirdi ("son işlem ne olum onu niye çevirmedin") - yani kural sadece kod/commit/sohbete değil, Claude'un yazdığı HER açıklayıcı metne (hafıza dosyaları dahil) uygulanıyor.

Bu repo (GymApp) zaten kendi açıklama-çevirme geçişini yapmıştı (commit `85b9483`, "Translate code comments to Turkish") - bu artık açık, kalıcı bir kural, tek seferlik bir iş değil. Commit mesajları da bundan sonra Türkçe olacak (hâlâ Claude/AI imza satırı yok, bkz. CLAUDE.md - bu sadece mesajın dilini değiştiriyor).

Tam gerekçe/ayrıntı GymAppApi'nin kendi hafıza dosyası kopyasında (`feedback-turkish-comments-and-commits.md`) yaşıyor - bu sadece ona işaret eden bir gösterge, repolar arası yerleşik kurala uygun olarak (bkz. `feedback-never-remove-registration.md`).
