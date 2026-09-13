class AiCapacity < Formula
  desc "Local dashboard of AI subscription allowances and prepaid balances"
  homepage "https://github.com/ryan-mahoney/CodexBar"
  url "https://github.com/ryan-mahoney/CodexBar/releases/download/ai-capacity-v0.1.0/ai-capacity-0.1.0-macos-arm64.tar.gz"
  version "0.1.0"
  sha256 "a432c377482e321eaf4be5998ef4737de6faa7301c79a2ebb85bb73ad491f29f"
  license all_of: ["MIT", "OFL-1.1", "Apache-2.0"]

  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on "python@3.14"

  def install
    libexec.install "ai_capacity", "launch.py", "report-cli", "licenses"
    (bin/"ai-capacity").write_env_script formula_opt_bin("python@3.14")/"python3.14",
                                        ["-I", "\"#{libexec}/launch.py\""], {}
    (bin/"ai-capacity-report").write_env_script libexec/"report-cli/codexbar", {}
  end

  def caveats
    <<~EOS
      Run ai-capacity to open the dashboard. Keep the terminal open.
      Press Ctrl+C to stop it. Use --no-open to leave the browser closed.
      Provider sign-ins and macOS Keychain permissions still apply.
      After an upgrade, stop and restart the dashboard.
    EOS
  end

  test do
    ENV["CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS"] = "1"
    ENV.delete("CODEXBAR_BIN")
    ENV.delete("OPENROUTER_API_KEY")
    ENV.delete("OPENROUTER_MANAGEMENT_API_KEY")
    assert_match "ai-capacity #{version}", shell_output("#{bin}/ai-capacity --version")
    assert_match "--no-open", shell_output("#{bin}/ai-capacity --help")
    assert_match "report", shell_output("#{bin}/ai-capacity-report report --help")
    system({ "CODEXBAR_RESOURCE_SMOKE" => "1" }, bin/"ai-capacity-report")

    # The installed dashboard uses its own binary without a source checkout or PATH lookup.
    system formula_opt_bin("python@3.14")/"python3.14", "-I", "-c", <<~PYTHON
      import sys
      from pathlib import Path
      sys.path.insert(0, #{libexec.to_s.inspect})
      from ai_capacity.server import default_binary
      assert Path(default_binary()) == Path(#{(libexec/"report-cli/codexbar").to_s.inspect})
    PYTHON

    # Run the real launcher from a different directory, with a synthetic report executable.
    # This test must not read account credentials or contact providers.
    fixture = testpath/"fixture-report"
    fixture.write <<~SH
      #!/bin/sh
      printf '%s\\n' '{"checkedAt":"2026-01-01T00:00:00Z","accounts":[{"provider":"deepseek","account":"Example account","kind":"balance","windows":[],"balances":[{"amount":42.8,"currency":"USD"}]}]}'
    SH
    fixture.chmod 0755
    port = free_port
    pid = fork do
      exec bin/"ai-capacity", "--no-open", "--no-opencode", "--codexbar", fixture.to_s, "--port", port.to_s
    end
    begin
      system formula_opt_bin("python@3.14")/"python3.14", "-I", "-c", <<~PYTHON
        import json, time
        from urllib.request import urlopen
        base = "http://127.0.0.1:#{port}"
        for attempt in range(100):
            try:
                with urlopen(base + "/api/report", timeout=1) as response:
                    payload = json.load(response)
                if payload.get("report"):
                    break
            except OSError:
                pass
            time.sleep(0.1)
        else:
            raise AssertionError("Dashboard did not return a report")
        rows = payload["report"]["accounts"]
        row = next(row for row in rows if row["provider"] == "deepseek")
        assert row["account"] == "Example account"
        assert row["balances"] == [{"amount": 42.8, "currency": "USD"}]
        for path, expected in [("/", "Current AI Provider Capacity"), ("/app.js", "fetch"), ("/app.css", "font-face")]:
            with urlopen(base + path, timeout=2) as response:
                assert expected in response.read().decode()
      PYTHON
    ensure
      Process.kill "INT", pid
      Process.wait pid
    end
  end
end
